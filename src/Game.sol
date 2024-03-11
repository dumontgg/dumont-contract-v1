// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
    mapping(uint256 => Card) public cards;
    mapping(uint256 => uint256) public numbersRevealed;

    uint256 public immutable gameId;
    uint256 public immutable gameDuration;

    IERC20 public immutable usdt;
    Vault public immutable vault;
    address public immutable manager;
    address public immutable player;

    /**
     * @notice Sets contract and player addresses, and sets a custom maxGuessesAllowed
     * @param _usdt The address of the USDT token
     * @param _vault The Vault contract address
     * @param _manager The server of the game that is allowed to submit the random hash of cards
     * @param _player The player that created the game using Vault contract
     * @param _gameId The ID of the game stored in Vault contract
     * @param _gameDuration The duration of the game. After that the game will be unplayable
     */
    constructor(
        IERC20 _usdt,
        Vault _vault,
        address _manager,
        address _player,
        uint256 _gameId,
        uint256 _gameDuration
    ) {
        usdt = _usdt;
        vault = _vault;
        manager = _manager;
        player = _player;
        gameId = _gameId;
        gameDuration = _gameDuration;
    }

    modifier onlyPlayer() {
        if (msg.sender != player) {
            revert NotAuthorized();
        }

        _;
    }

    modifier onlyManager() {
        if (msg.sender != manager) {
            revert NotAuthorized();
        }

        _;
    }

    function initialize(
        bytes[52] calldata _hashedCards
    ) external onlyNotInitialized onlyManager {
        initializeContract();

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
    ) external onlyPlayer onlyInitialized {
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

    function getRate(uint256[] memory _cards) public view returns (uint256) {
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
    ) private view returns (bool isPlayerWinner) {
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
        uint256 _revealedNumber,
        string calldata _revealedSalt
    ) external onlyManager onlyInitialized {
        Card storage card = cards[_index];

        card.revealedSalt = _revealedSalt;
        card.revealedNumber = _revealedNumber;

        bool isPlayerWon = checkCardRevealed(
            card.guessedNumbers,
            card.revealedNumber
        );

        uint256[] memory guessedNumbers = new uint256[](
            card.guessedNumbers.length
        );

        for (uint256 i = 0; i < card.guessedNumbers.length; i++) {
            guessedNumbers[i] = card.guessedNumbers[i];
        }

        /*
         * TODO: what would be the optimal way of storing the bet amount?
         * ANSWER: Amount should be transferred to Vault after guessCard and everything will be
         * handled from the Vault itself.
         */

        if (isPlayerWon) {
            vault.playerLostGame(
                gameId,
                card.betAmount,
                getRate(guessedNumbers),
                player
            );
        } else {
            usdt.transferFrom(address(this), address(vault), card.betAmount);
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
