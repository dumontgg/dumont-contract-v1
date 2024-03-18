// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UD60x18, ud} from "@prb/math/src/UD60x18.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IGame} from "./interfaces/IGame.sol";
import {IGameFactory} from "./interfaces/IGameFactory.sol";
import {Initializable} from "./helpers/Initializable.sol";
import {Vault} from "./Vault.sol";

/**
 * @title A single game contract playable for the a single player
 * @author X team
 * @notice Server sets the hashed numbers inside the contract and the player has to guess each card
 * @dev The contract uses a commit-reveal mechanism to hide the deck of cards at first
 */
contract Game is Initializable, IGame {
    using SafeERC20 for IERC20;

    uint256 public cardsRevealed;
    uint256 public cardsFreeRevealed;
    uint256[13] public numbersRevealedCount;
    mapping(uint256 => Card) public cards;

    IERC20 public immutable usdt;
    Vault public immutable vault;
    address public immutable revealer;
    address public immutable player;
    uint256 public immutable gameId;
    uint256 public immutable gameDuration;
    uint256 public immutable claimableAfter;
    uint256 public immutable maxFreeReveals;
    bool public constant SHOULD_GET_REWARDS = true;

    /**
     * @notice Sets contract and player addresses, and sets a custom maxGuessesAllowed
     * @param _usdt The address of the USDT token
     * @param _vault The Vault contract address
     * @param _revealer The server of the game that is allowed to submit the random hash of cards
     * @param _player The player that created the game using Vault contract
     * @param _gameId The ID of the game stored in Vault contract
     * @param _gameDuration The duration of the game. After that the game will be unplayable
     * @param _claimableAfter The duration which the user can claim their win if revealer does not reveal
     * @param _maxFreeReveals The maximum amount of free reveals a player can request
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
    }

    modifier onlyPlayer() {
        if (msg.sender != player) {
            revert NotAuthorized(msg.sender);
        }

        _;
    }

    modifier onlyRevealer() {
        if (msg.sender != revealer) {
            revert NotAuthorized(msg.sender);
        }

        _;
    }

    function initialize(
        bytes[52] calldata _hashedCards
    ) external onlyNotInitialized onlyRevealer {
        initializeContract();

        for (uint256 i = 0; i < 52; ) {
            cards[i].hashed = _hashedCards[i];
            cards[i].status = CardStatus.HIDDEN;

            unchecked {
                ++i;
            }
        }
    }

    function guessCard(
        uint256 _cardIndex,
        uint256 _betAmount,
        bool[13] calldata _guessedNumbers
    ) external onlyPlayer onlyInitialized {
        Card storage _card = cards[_cardIndex];

        if (_cardIndex > 51) {
            revert InvalidGameIndex();
        }

        if (_card.status != CardStatus.HIDDEN) {
            revert CardIsNotHidden(_cardIndex);
        }

        if (_betAmount < vault.minimumBetAmount()) {
            revert BetAmountIsLessThanMinimum();
        }

        uint256 totalWinningBetAmount = getGuessOdds(_guessedNumbers)
            .mul(ud(_betAmount))
            .unwrap();

        if (totalWinningBetAmount > vault.getMaximumBetAmount()) {
            revert BetAmountIsGreaterThanMaximum();
        }

        usdt.safeTransferFrom(msg.sender, address(vault), _betAmount);

        _card.betAmount = _betAmount;
        _card.guessedAt = block.timestamp;
        _card.status = CardStatus.GUESSED;
        _card.guessedNumbers = _guessedNumbers;
        _card.totalAmount = totalWinningBetAmount;

        emit PlayerGuessed(_cardIndex, _guessedNumbers, _betAmount);
    }

    function getGuessOdds(
        bool[13] memory _cards
    ) public view returns (UD60x18) {
        uint256 remainingCards = 52 - cardsRevealed;
        uint256 remainingSelectedCard = 0;

        for (uint256 i = 0; i < 13; ++i) {
            if (_cards[i]) {
                remainingSelectedCard += 4 - numbersRevealedCount[i];
            }
        }

        UD60x18 a = ud(remainingCards);
        UD60x18 b = a.div(ud(remainingSelectedCard));

        return b;
    }

    function claimWin(uint256 _index) external onlyPlayer onlyInitialized {
        Card storage _card = cards[_index];

        if (_card.status != CardStatus.GUESSED) {
            revert CardIsNotGuessed(_index);
        }

        if (_card.guessedAt + claimableAfter <= block.timestamp) {
            revert NotYetTimeToClaim(_index);
        }

        _card.status = CardStatus.CLAIMED;

        vault.transferPlayerRewards(
            gameId,
            _card.betAmount,
            _card.totalAmount,
            player,
            true,
            !SHOULD_GET_REWARDS
        );

        emit CardClaimed(_index, block.timestamp);
    }

    function revealCard(
        uint256 _index,
        uint256 _revealedNumber,
        string calldata _revealedSalt
    ) external onlyRevealer onlyInitialized {
        Card storage _card = cards[_index];

        if (_card.status != CardStatus.GUESSED) {
            revert CardIsNotHidden(_index);
        }

        _card.status = CardStatus.REVEALED;
        _card.revealedSalt = _revealedSalt;
        _card.revealedNumber = _revealedNumber;

        ++numbersRevealedCount[_revealedNumber];

        bool isPlayerWon = checkCardRevealed(
            _card.guessedNumbers,
            _card.revealedNumber
        );

        vault.transferPlayerRewards(
            gameId,
            _card.betAmount,
            _card.totalAmount,
            player,
            isPlayerWon,
            SHOULD_GET_REWARDS
        );

        emit CardRevealed(_index, _revealedNumber, _revealedSalt);
    }

    function requestRevealFreeCard(
        uint256 _index
    ) external onlyPlayer onlyInitialized {
        Card storage _card = cards[_index];

        if (_card.status != CardStatus.HIDDEN) {
            revert CardIsNotHidden(_index);
        }

        _card.status = CardStatus.FREE_REVEALE_REQUESTED;
        ++cardsFreeRevealed;

        emit RevealFreeCardRequested(_index, block.timestamp);
    }

    function revealFreeCard(
        uint256 _index,
        uint256 _revealedNumber,
        string calldata _revealedSalt
    ) external onlyRevealer onlyInitialized {
        Card storage _card = cards[_index];

        if (_card.status != CardStatus.FREE_REVEALE_REQUESTED) {
            revert CardIsNotFreeRevealed();
        }

        _card.status = CardStatus.FREE_REVEALED;
        _card.revealedSalt = _revealedSalt;
        _card.revealedNumber = _revealedNumber;

        ++numbersRevealedCount[_revealedNumber];

        emit CardRevealed(_index, _revealedNumber, _revealedSalt);
    }

    function checkCardRevealed(
        bool[13] memory _guessedNumbers,
        uint256 _revealedNumber
    ) private pure returns (bool isPlayerWinner) {
        isPlayerWinner = false;

        for (uint256 i = 0; i < 13; ++i) {
            if (_guessedNumbers[i] && i == _revealedNumber) {
                isPlayerWinner = true;

                break;
            }
        }
    }
}
