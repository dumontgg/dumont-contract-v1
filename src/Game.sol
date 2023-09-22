// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IVault} from "./interfaces/IVault.sol";

/**
 * @title A single game contract playable for the a single player
 * @author X team
 * @notice Server sets the hashed numbers inside the contract and the player has to guess each card
 * @dev The contract uses a commit-reveal mechanism to hide the deck of cards at first
 */
contract Game {
    struct RevealedCard {
        // number is between 0 and 51 representing the 52 cards of the deck
        uint8 number;
        string salt;
    }

    // GameID is stored to communicate to the Vault contract more easily
    uint256 public gameId;

    // isInitialized will change to 2 when the game contract is called
    // by the server to store the hash of the random deck of cards
    uint8 public isInitialized = 1;

    uint8 public index = 0; // ????

    // Keeps track of the number of cards that are revealed.
    // This number should not surpass MAX_GUESSES_ALLOWED
    uint8 public numbersRevealed;

    // The maximum amount of cards that can be revealed in a game from a deck.
    uint8 public maxGuessesAllowed;

    IVault public vault;
    address public server;
    address public player;

    // A random deck of hashed cards. Each card is hashed with a unique salt
    bytes[52] public deckHashed;

    // Specifies which cards are guessed
    bool[52] public isCardGuessed;

    // Stores the number (suit + rank) and the salt of each card
    RevealedCard[52] public deck;

    /**
     * @notice Sets contract and player addresses, and sets a custom maxGuessesAllowed
     * @param _vault The Vault contract address
     * @param _server The server of the game that is allowed to submit the random hash of cards
     * @param _player The player that created the game using Vault contract
     * @param _gameId The ID of the game stored in Vault contract
     * @param _maxGuessesAllowed The maximum amount of guesses a player can have each game
     */
    constructor(IVault _vault, address _server, address _player, uint256 _gameId, uint8 _maxGuessesAllowed) {
        vault = _vault;
        server = _server;
        player = _player;
        gameId = _gameId;
        maxGuessesAllowed = _maxGuessesAllowed;
    }

    modifier onlyPlayer() {
        // _require(msg.sender == player, ErrorCodes.UNAUTHORIZED);

        _;
    }

    modifier onlyServer() {
        // _require(msg.sender == server, ErrorCodes.UNAUTHORIZED);

        _;
    }

    // we should implement a deadline for each game. 10min for example
    modifier notInitialized() {
        // _require(isInitialized == 2, ErrorCodes.ALREADY_INITIALIZED);

        _;
    }

    function initialize() public notInitialized onlyServer {
        isInitialized = 2;
    }

    function guessCard() public onlyPlayer {}
}
