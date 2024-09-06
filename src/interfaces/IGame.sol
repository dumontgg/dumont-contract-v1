// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title A single-player game contract where the player guesses card numbers
 * @notice The server sets hashed numbers inside the contract, and the player can guess each card
 * @dev The contract uses a commit-reveal mechanism to hide the deck of cards initially
 */
interface IGame {
    enum CardStatus {
        SECRETED,
        GUESSED,
        CLAIMED,
        FREE_REVEAL_REQUESTED,
        REVEALED
    }

    struct Card {
        uint256 betAmount;
        uint256 totalAmount;
        uint256 houseEdgeAmount;
        uint256 requestedAt;
        uint256 revealedNumber;
        uint256 guessedNumbers;
        bytes32 hash;
        bytes32 revealedSalt;
        CardStatus status;
    }

    /**
     * @notice Emitted when revealCard is called for a specific card
     * @param _gameId Game id
     * @param _index Index of the card
     * @param _number Revealed number for the card
     * @param _salt Revealed salt for the card
     */
    event CardRevealed(uint256 indexed _gameId, uint256 indexed _index, uint256 indexed _number, bytes32 _salt);

    /**
     * @notice Emitted when guessCard is called for a specific card
     * @param _gameId Game id
     * @param _index Index of the card
     * @param _usdcAmount USDC amount betted for the card by the player
     * @param _guessedNumbers Numbers guessed by the player
     */
    event CardGuessed(
        uint256 indexed _gameId, uint256 indexed _index, uint256 indexed _usdcAmount, uint256 _guessedNumbers
    );

    /**
     * @notice Emitted when requestFreeRevealCard is called
     * @param _gameId Game id
     * @param _index Index of the card
     * @param _timestamp Timestamp
     */
    event RevealFreeCardRequested(uint256 indexed _gameId, uint256 indexed _index, uint256 _timestamp);

    /**
     * @notice Emitted when claimWin is called
     * @param _gameId Game id
     * @param _index Index of the card
     * @param _timestamp Timestamp
     */
    event CardClaimed(uint256 indexed _gameId, uint256 indexed _index, uint256 _timestamp);

    /**
     * @notice Emitted when the game is initialize by a revealer
     * @param _gameId Game id
     */
    event GameInitialized(uint256 indexed _gameId);

    /**
     * @notice Thrown when card is not secreted but functions are called
     * @param _gameId Game id
     * @param _index index Index of the card
     */
    error CardIsNotSecret(uint256 _gameId, uint256 _index);

    /**
     * @notice Thrown when maximum amount of free reveals is requested and more is being requested
     * @param _gameId Game id
     */
    error MaximumFreeRevealsRequested(uint256 _gameId);

    /**
     * @notice Thrown when the card is not guessed but function revealCard or else is called
     * @param _gameId Game id
     * @param _index Index of the card
     */
    error CardIsNotGuessed(uint256 _gameId, uint256 _index);

    /**
     * @notice Thrown when the card status is not FREE_REVEAL_REQUESTED but revealCard is called
     * @param _gameId Game id
     * @param _index Index of the card
     */
    error CardStatusIsNotFreeRevealRequested(uint256 _gameId, uint256 _index);

    /**
     * @notice Thrown when the bet amount for a card is less than the minumum specified by the vault
     * @param _gameId Game id
     */
    error BetAmountIsLessThanMinimum(uint256 _gameId);

    /**
     * @notice Thrown when the bet amount for a card is greater than the maximum specified by the vault
     * @param _gameId Game id
     * @param _totalAmount Total amount of the bet, meaning betAmount times the rate
     */
    error BetAmountIsGreaterThanMaximum(uint256 _gameId, uint256 _totalAmount);

    /**
     * @notice Thrown when the caller is not authorized
     * @param _gameId Game id
     * @param _caller Address of the caller
     */
    error NotAuthorized(uint256 _gameId, address _caller);

    /**
     * @notice Thrown when game index is out of bound (0 - 51)
     * @param _gameId Game id
     * @param _index Index of the card
     */
    error InvalidGameIndex(uint256 _gameId, uint256 _index);

    /**
     * @notice Thrown when no card or all cards are guessed
     * @param _gameId Game id
     * @param _guessedNumbers The guessed numbers
     */
    error InvalidNumbersGuessed(uint256 _gameId, uint256 _guessedNumbers);

    /**
     * @notice Thrown when claimWin is called before the due time
     * @param _gameId Game id
     * @param _index Index of the card
     */
    error NotYetTimeToClaim(uint256 _gameId, uint256 _index);

    /**
     * @notice Thrown when the game is expired
     * @param _gameId Game id
     */
    error GameExpired(uint256 _gameId);

    /**
     * @notice Thrown when the given salt is invalid
     * @param _gameId Game id
     * @param _index Index of the card
     * @param _number Revealed number
     * @param _salt Revealed salt
     */
    error InvalidSalt(uint256 _gameId, uint256 _index, uint256 _number, bytes32 _salt);

    /**
     * @notice Thrown when the remaining selected cards is zero
     * @param _gameId Game id
     * @param _numbers The selected numbers to get the rate
     */
    error DivisionByZeroSelectedCards(uint256 _gameId, uint256 _numbers);

    /**
     * @notice Thrown when the card is not revealed after CLAIMABLE_AFTER and the operator
     *  tries to reveal the card
     * @param _gameId Game id
     * @param _index Index of the card
     */
    error CardIsAlreadyClaimable(uint256 _gameId, uint256 _index);

    /**
     * @notice Thrown when the remaining selected cards is equal to remaining cards
     * @param _gameId Game id
     * @param _numbers The selected ranks to get the rate
     */
    error InvalidSelectedCards(uint256 _gameId, uint256 _numbers);

    /**
     * @notice Initializes the contract by committing the deck of cards
     * @param _hashedDeck The hash of a random deck of cards
     */
    function initialize(bytes32[52] calldata _hashedDeck) external;

    /**
     * @notice Stores the player's guess
     * @param _index Index of the card
     * @param _betAmount The amount of USDC that the player bets
     * @param _guessedNumbers Numbers that the player guessed
     */
    function guessCard(uint256 _index, uint256 _betAmount, uint256 _guessedNumbers) external;

    /**
     * @notice Requests a secret card to be revealed for free
     * @param _index Index of the card
     */
    function requestFreeRevealCard(uint256 _index) external;

    /**
     * @notice Claims the player as the winner for a specific card if the revealer does not reveal
     * the card after the claimableAfter duration
     * @param _index Index of the card
     */
    function claimWin(uint256 _index) external;

    /**
     * @notice Reveals a card and decides the winner and transfers rewards to the player
     * @param _index Index of the card
     * @param _number The revealed number of the card
     * @param _salt The salt that was used to hash the card
     */
    function revealCard(uint256 _index, uint256 _number, bytes32 _salt, bool isFreeReveal) external;

    /**
     * @notice Get cards by their index from 0 to 51
     * @param _index Index of the card
     */
    function cards(uint256 _index) external returns (Card memory);
}
