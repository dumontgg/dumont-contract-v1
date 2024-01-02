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

    uint256 public constant LOCKED = 2;
    uint256 public constant UNLOCKED = 1;
    uint256 public isLocked;

    // TODO: should i use IVault or Vault here? (i'm calling a public state variable inside here)
    IERC20 public usdt;
    Vault public vault;
    address public server;
    address public player;

    event CardRevealed(uint256 _index, uint256 _number, string _salt);
    event PlayerGuessed(uint256 _index, uint256 _number, uint256 _daiAmount);

    error AlreadyGuessed(uint256 _index, uint256 _guessedNumber);
    error BetAmountIsLessThanMinimum();
    error BetAmountIsGreaterThanMaximum();
    error NotAuthorized();
    error InvalidGameIndex();
    error GameIsUnlocked();
    error GameIsLocked();
    error GameIsNotInitialized();
    error GameIsAlreadyInitialized();

    /**
     * @notice Sets contract and player addresses, and sets a custom maxGuessesAllowed
     * @param _usdt The address of the USDT token
     * @param _vault The Vault contract address
     * @param _server The server of the game that is allowed to submit the random hash of cards
     * @param _player The player that created the game using Vault contract
     * @param _gameId The ID of the game stored in Vault contract
     * @param _gameDuration The duration of the game. After that the game will be unplayable
     */
    constructor(IERC20 _usdt, Vault _vault, address _server, address _player, uint256 _gameId, uint256 _gameDuration) {
        usdt = _usdt;
        vault = _vault;
        server = _server;
        player = _player;
        gameId = _gameId;
        gameDuration = _gameDuration;

        isInitialized = NOT_INITIALIZED;
        isLocked = UNLOCKED;
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

    modifier shouldBeLocked() {
        if (isLocked == UNLOCKED) {
            revert GameIsUnlocked();
        }

        _;
    }

    modifier shouldBeUnlocked() {
        if (isLocked == LOCKED) {
            revert GameIsLocked();
        }

        _;
    }

    function initialize(bytes[52] calldata _hashedCards) external shouldNotBeInitialized onlyServer {
        isInitialized = INITIALIZED;

        for (uint256 i = 0; i < 52;) {
            cards[i].isInitialized = true;
            cards[i].hashed = _hashedCards[i];

            unchecked {
                ++i;
            }
        }
    }

    function guessCard(uint256 _index, uint8 _number, uint256 _daiAmount)
        external
        onlyPlayer
        shouldBeInitialized
        shouldBeUnlocked
    {
        if (_index > 51) {
            revert InvalidGameIndex();
        }

        if (cards[_index].isGuessed) {
            revert AlreadyGuessed(_index, cards[_index].guessedNumber);
        }

        if (_daiAmount < vault.minimumBetAmount()) {
            revert BetAmountIsLessThanMinimum();
        }

        if (getRate(_daiAmount, _number) > vault.getMaximumBetAmount()) {
            revert BetAmountIsGreaterThanMaximum();
        }

        isLocked = LOCKED;

        usdt.safeTransferFrom(msg.sender, address(this), _daiAmount);

        // dai miad haminja bad ke moshakhas shod, age yaroo bakhte bood ke mire be vault
        // age ham borde bood ke hamoon DAI + ye rate i behesh mirese :D
        // ba amir ansari check kon ke rate chetor calculate mishe

        // check min amount
        // lock this function
        // transfer the amount to the vault
        // ?? what if we enforce the user to approve the VAULT and call vault here with the player

        cards[_index].isGuessed = true;
        cards[_index].guessedNumber = _number;

        // Get the rate and check for max daiAmount user can get and restrict that
        // why ? what's the point? rate should be a view function and rthe client can call it anytime
        // there should be a minimum/maximum amount of DAI that people can use to
        // getRate(index, number);

        // minimum and maximum dai amount should be set on the vault

        emit PlayerGuessed(_index, _number, _daiAmount);
    }

    function getRate(uint256 _daiAmount, uint8 _card) public view returns (uint256) {
        uint256 remainingCards = 52 - cardsRevealed;

        // TODO: make sure this is correct?
        return (remainingCards / numbersRevealed[_card]) * _daiAmount;
    }

    function revealCard(uint256 _index, uint8 _revealedNumber, string calldata _revealedSalt)
        external
        onlyServer
        shouldBeLocked
    {
        isLocked = UNLOCKED;

        cards[_index].revealedSalt = _revealedSalt;
        cards[_index].revealedNumber = _revealedNumber;

        emit CardRevealed(_index, _revealedNumber, _revealedSalt);

        /*
        calculate the winner
        decide of they won
        transfer the tokens
        interact with the vault
        */
    }
}
