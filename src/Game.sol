// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IGame} from "./interfaces/IGame.sol";
import {Vault} from "./Vault.sol";

/**
 * @title A single game contract playable for the a single player
 * @author X team
 * @notice Server sets the hashed numbers inside the contract and the player has to guess each card
 * @dev The contract uses a commit-reveal mechanism to hide the deck of cards at first
 */
contract Game is IGame {
    using SafeERC20 for IERC20;

    uint256 public immutable gameId;
    uint256 public immutable gameDuration;
    uint256 public cardsRevealed;
    mapping(uint256 => Card) public cards;
    mapping(uint256 => uint256) public numbersRevealed;

    uint256 public constant INITIALIZED = 2;
    uint256 public constant NOT_INITIALIZED = 1;
    uint256 public isInitialized;

    IERC20 public usdt;
    Vault public vault;
    address public server;
    address public player;

    /**
     * @notice Sets contract and player addresses, and sets a custom maxGuessesAllowed
     * @param _usdt The address of the USDT token
     * @param _vault The Vault contract address
     * @param _server The server of the game that is allowed to submit the random hash of cards
     * @param _player The player that created the game using Vault contract
     * @param _gameId The ID of the game stored in Vault contract
     * @param _gameDuration The duration of the game. After that the game will be unplayable
     */
    constructor(
        IERC20 _usdt,
        Vault _vault,
        address _server,
        address _player,
        uint256 _gameId,
        uint256 _gameDuration
    ) {
        usdt = _usdt;
        vault = _vault;
        server = _server;
        player = _player;
        gameId = _gameId;
        gameDuration = _gameDuration;

        isInitialized = NOT_INITIALIZED;
    }

    modifier onlyPlayer() {
        if (msg.sender != player) {
            revert NotAuthorized();
        }

        _;
    }

    modifier onlyServer() {
        if (msg.sender != server) {
            revert NotAuthorized();
        }

        _;
    }

    modifier shouldBeInitialized() {
        if (isInitialized == NOT_INITIALIZED) {
            revert GameIsNotInitialized();
        }

        _;
    }

    modifier shouldNotBeInitialized() {
        if (isInitialized == INITIALIZED) {
            revert GameIsAlreadyInitialized();
        }

        _;
    }

    function initialize(
        bytes[52] calldata _hashedCards
    ) external shouldNotBeInitialized onlyServer {
        isInitialized = INITIALIZED;

        for (uint256 i = 0; i < 52; ) {
            cards[i].hashed = _hashedCards[i];

            unchecked {
                ++i;
            }
        }
    }

    function guessCard(
        uint256 _cardIndex,
        uint256[] calldata _guessedNumbers,
        uint256 _betAmount
    ) external onlyPlayer shouldBeInitialized {
        if (_cardIndex > 51) {
            revert InvalidGameIndex();
        }

        if (cards[_cardIndex].isGuessed) {
            revert AlreadyGuessed(_cardIndex, cards[_cardIndex].guessedNumbers);
        }

        if (_betAmount < vault.minimumBetAmount()) {
            revert BetAmountIsLessThanMinimum();
        }

        uint256 totalWinningBetAmount = getRate(_guessedNumbers) * _betAmount;

        // Check if the bet is going to be higher than the maximum possible amount
        if (totalWinningBetAmount > vault.getMaximumBetAmount()) {
            revert BetAmountIsGreaterThanMaximum();
        }

        usdt.safeTransferFrom(msg.sender, address(this), _betAmount);

        cards[_cardIndex].isGuessed = true;
        cards[_cardIndex].betAmount = _betAmount;
        cards[_cardIndex].guessedNumbers = _guessedNumbers;

        emit PlayerGuessed(_cardIndex, _guessedNumbers, _betAmount);
    }

    function getRate(uint256[] calldata _cards) public view returns (uint256) {
        uint256 remainingCards = 52 - cardsRevealed;

        uint256 makhraj = 0;

        // check if all _cards values are unique
        for (uint256 i = 0; i < _cards.length; ++i) {
            makhraj += 4 - numbersRevealed[_cards[i]];
        }

        // check if the decimal rounding does not ruin the rate
        return remainingCards / makhraj;
    }

    function checkCardRevealed(
        uint256[] storage _guessedNumbers,
        uint256 _revealedNumber
    ) private returns (bool isPlayerWinner) {
        isPlayerWinner = false;

        for (uint256 i = 0; i < _guessedNumbers.length; ++i) {
            if (_guessedNumbers[i] == _revealedNumber) {
                isPlayerWinner = true;

                break;
            }
        }
    }

    function revealCard(
        uint256 _index,
        uint8 _revealedNumber,
        string calldata _revealedSalt
    ) external onlyServer {
        cards[_index].revealedSalt = _revealedSalt;
        cards[_index].revealedNumber = _revealedNumber;

        bool isPlayerWon = checkCardRevealed(
            cards[_index].guessedNumbers,
            cards[_index].revealedNumber
        );

        /*
         * TODO: what would be the optimal way of storing the bet amount?
         * ANSWER: Amount should be transferred to Vault after guessCard and everything will be
         * handled from the Vault itself.
         */

        if (isPlayerWon) {
            Vault.gameLost(
                gameId,
                getRate(cards[_index].guessedNumbers),
                cards[_index].betAmount
            );
        } else {
            usdt.transferFrom(
                address(this),
                address(Vault),
                cards[_index].betAmount
            );
            // ???
        }

        emit CardRevealed(_index, _revealedNumber, _revealedSalt);

        /*
        decide of they won
        transfer the tokens
        interact with the vault
        */
    }
}
