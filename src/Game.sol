// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {console2} from "forge-std/console2.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UD60x18, ud} from "@prb/math/src/UD60x18.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IGame} from "./interfaces/IGame.sol";
import {IGameFactory} from "./interfaces/IGameFactory.sol";
import {Initializable} from "./helpers/Initializable.sol";
import {Vault} from "./Vault.sol";

/**
 * @title A single-player game contract where the player guesses card numbers
 * @notice The server sets hashed numbers inside the contract, and the player can guess each card
 * @dev The contract uses a commit-reveal mechanism to hide the deck of cards initially
 */
contract Game is Initializable, IGame {
    using SafeERC20 for IERC20;

    bool public constant SHOULD_RECEIVE_REWARDS = true;
    uint256 public constant MAXIMUM_GUESS_NUMBER = 8191;

    uint256 public cardsRevealed = 0;
    uint256 public cardsFreeRevealed = 0;

    uint256[13] public revealedCardNumbersCount;

    mapping(uint256 => Card) private _cards;

    IERC20 public immutable usdt;
    Vault public immutable vault;
    address public immutable player;
    address public immutable revealer;
    uint256 public immutable gameId;
    uint256 public immutable gameDuration;
    uint256 public immutable gameCreatedAt;
    uint256 public immutable claimableAfter;
    uint256 public immutable maxFreeReveals;

    /**
     * @notice Modifier to restrict access to player only
     */
    modifier onlyPlayer() {
        if (msg.sender != player) {
            revert NotAuthorized(msg.sender);
        }

        _;
    }

    /**
     * @notice Modifier to restrict access to revealer only
     */
    modifier onlyRevealer() {
        if (msg.sender != revealer) {
            revert NotAuthorized(msg.sender);
        }

        _;
    }

    /**
     * @notice Modifier to restrict the player from playing after the gameDuration passes
     */
    modifier notExpired() {
        if (gameDuration + gameCreatedAt < block.timestamp) {
            revert GameExpired();
        }

        _;
    }

    /**
     * @notice Sets contract and player addresses
     * @param _usdt The address of the USDT token
     * @param _vault The Vault contract address
     * @param _revealer The game server that submits the random hash of cards and reveals the guessed cards
     * @param _player The player that created the game using the GameFactory contract
     * @param _gameId The ID of the game stored in the GameFactory contract
     * @param _gameDuration The duration of the game. After that, the game is unplayable
     * @param _claimableAfter The duration during which the user can claim their win if the revealer does not reveal
     * @param _maxFreeReveals The maximum number of free reveals a player can request
     */
    constructor(
        IERC20 _usdt,
        Vault _vault,
        address _revealer,
        address _player,
        uint256 _gameId,
        uint256 _gameDuration,
        uint256 _claimableAfter,
        uint256 _maxFreeReveals
    ) {
        usdt = _usdt;
        vault = _vault;
        revealer = _revealer;
        player = _player;
        gameId = _gameId;
        gameDuration = _gameDuration;
        claimableAfter = _claimableAfter;
        maxFreeReveals = _maxFreeReveals;

        gameCreatedAt = block.timestamp;
    }

    /**
     * @notice Initializes the contract by committing the deck of cards
     * @param _hashedDeck The hash of a random deck of cards
     */
    function initialize(bytes32[52] calldata _hashedDeck) external onlyNotInitialized onlyRevealer {
        initializeContract();

        for (uint256 i = 0; i < 52;) {
            _cards[i].hash = _hashedDeck[i];
            _cards[i].status = CardStatus.SECRETED;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Stores the player's guess
     * @param _index Index of the card
     * @param _betAmount The amount of USDT that the player bets
     * @param _guessedNumbers Numbers that the player guessed
     */
    function guessCard(uint256 _index, uint256 _betAmount, uint256 _guessedNumbers)
        external
        onlyPlayer
        onlyInitialized
        notExpired
    {
        Card storage _card = _cards[_index];

        if (_index > 51) {
            revert InvalidGameIndex();
        }

        if (_guessedNumbers >= MAXIMUM_GUESS_NUMBER || _guessedNumbers == 0) {
            revert InvalidNumbersGuessed(_guessedNumbers);
        }

        if (_card.status != CardStatus.SECRETED) {
            revert CardIsNotSecret(_index);
        }

        if (_betAmount < vault.minimumBetAmount()) {
            revert BetAmountIsLessThanMinimum();
        }

        uint256 totalWinningBetAmount = getGuessRate(_guessedNumbers).mul(ud(_betAmount)).unwrap();

        if (totalWinningBetAmount > vault.getMaximumBetAmount()) {
            revert BetAmountIsGreaterThanMaximum();
        }

        usdt.safeTransferFrom(msg.sender, address(vault), _betAmount);

        _card.betAmount = _betAmount;
        _card.guessedAt = block.timestamp;
        _card.status = CardStatus.GUESSED;
        _card.guessedNumbers = _guessedNumbers;
        _card.totalAmount = totalWinningBetAmount;

        emit PlayerGuessed(_index, _betAmount, _guessedNumbers);
    }

    /**
     * @notice Requests a secret card to be revealed for free
     * @param _index Index of the card
     */
    function requestFreeRevealCard(uint256 _index) external onlyPlayer onlyInitialized notExpired {
        Card storage _card = _cards[_index];

        if (cardsFreeRevealed == maxFreeReveals) {
            revert MaximumFreeRevealsRequested();
        }

        if (_card.status != CardStatus.SECRETED) {
            revert CardIsNotSecret(_index);
        }

        ++cardsFreeRevealed;
        _card.status = CardStatus.FREE_REVEAL_REQUESTED;

        emit RevealFreeCardRequested(_index, block.timestamp);
    }

    /**
     * @notice Returns the rate of betting with selected numbers without considering the house edge
     * @param _numbers Selected numbers out of 13
     * @return rate The pure rate without considering the house edge
     */
    function getGuessRate(uint256 _numbers) public view returns (UD60x18 rate) {
        uint256 remainingCards = 52 - cardsRevealed;
        uint256 remainingSelectedCard = 0;

        for (uint256 i = 0; i < 13; ++i) {
            if ((_numbers & (1 << i)) > 0) {
                remainingSelectedCard += 4 - revealedCardNumbersCount[i];
            }
        }

        rate = ud(remainingCards).div(ud(remainingSelectedCard));
    }

    /**
     * @notice Claims the player as the winner for a specific card if the revealer does not reveal
     * the card after the claimableAfter duration
     * @param _index Index of the card
     */
    function claimWin(uint256 _index) external onlyPlayer onlyInitialized {
        Card storage _card = _cards[_index];

        if (_card.status != CardStatus.GUESSED) {
            revert CardIsNotGuessed(_index);
        }

        if (_card.guessedAt + claimableAfter <= block.timestamp) {
            revert NotYetTimeToClaim(_index);
        }

        _card.status = CardStatus.CLAIMED;

        vault.transferPlayerRewards(gameId, _card.betAmount, _card.totalAmount, player, true, !SHOULD_RECEIVE_REWARDS);

        emit CardClaimed(_index, block.timestamp);
    }

    /**
     * @notice Reveals a card and decides the winner and transfers rewards to the player
     * @param _index Index of the card
     * @param _number The revealed number of the card
     * @param _salt The salt that was used to hash the card
     */
    function revealCard(uint256 _index, uint256 _number, bytes32 _salt, bool isFreeReveal)
        external
        onlyRevealer
        onlyInitialized
    {
        uint256 rank = _number % 13;

        Card storage _card = _cards[_index];

        if (isFreeReveal) {
            if (_card.status != CardStatus.FREE_REVEAL_REQUESTED) {
                revert CardStatusIsNotFreeRevealRequested(_index);
            }
        } else {
            if (_card.status != CardStatus.GUESSED) {
                revert CardIsNotSecret(_index);
            }
        }

        verifySalt(_index, _number, _salt);

        _card.status = CardStatus.REVEALED;
        _card.revealedSalt = _salt;
        _card.revealedNumber = _number;

        ++revealedCardNumbersCount[rank];

        if (!isFreeReveal) {
            bool isWinner = isPlayerWinner(_card.guessedNumbers, rank);

            vault.transferPlayerRewards(
                gameId, _card.betAmount, _card.totalAmount, player, isWinner, SHOULD_RECEIVE_REWARDS
            );
        }

        emit CardRevealed(_index, _number, _salt);
    }

    // TODO:
    function cards(uint256 _index) public view returns (Card memory) {
        return _cards[_index];
    }

    /**
     * @notice Determines if the player is the winner based on their guesses and the revealed number
     * @param _guessedNumbers Player's guesses
     * @param _number The revealed number of the card
     */
    function isPlayerWinner(uint256 _guessedNumbers, uint256 _number) private pure returns (bool isWinner) {
        isWinner = false;

        for (uint256 i = 0; i < 13; ++i) {
            if ((_guessedNumbers & (1 << i)) > 0 && i == _number) {
                isWinner = true;

                break;
            }
        }
    }

    /**
     * @notice Verifies the hash stored in the blockchain with the revealed number and salt
     * @param _index Index of the card
     * @param _number The revealed number of the card
     * @param _salt The salt that was used to hash the card
     */
    function verifySalt(uint256 _index, uint256 _number, bytes32 _salt) private view {
        Card memory card = _cards[_index];

        bytes32 hash = keccak256(abi.encodePacked(_number, _salt));

        if (card.hash != hash) {
            revert InvalidSalt(_index, _number, _salt);
        }
    }
}
