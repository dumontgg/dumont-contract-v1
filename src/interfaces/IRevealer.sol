// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title Revealer Contract
 * @notice Manages the revelation of cards from multiple games
 */
interface IRevealer {
    struct RevealedCard {
        address game;
        bool isFreeReveal;
        uint256 index;
        uint256 number;
        bytes32 salt;
    }

    struct InitializeGame {
        address game;
        bytes32[52] hashedDeck;
    }

    /**
     * @notice Emitted when a card is revealed
     * @param _revealer The address of the entity revealing the card
     * @param _game The address of the game from which the card is revealed
     * @param _index The index of the revealed card
     */
    event CardRevealed(address indexed _revealer, address indexed _game, uint256 indexed _index);

    /**
     * @notice Emitted when a game is initialized
     * @param _revealer The address of the entity revealing the card
     * @param _game The address of the game that is initialized
     */
    event GameInitialized(address indexed _revealer, address indexed _game);

    function REVEALER_ROLE() external returns (bytes32);

    /**
     * @notice Reveals a card
     * @param _card The details of the revealed card
     */
    function revealCard(RevealedCard calldata _card) external;

    /**
     * @notice Reveals multiple cards from a single or different games
     * @param _cards The details of the revealed cards
     */
    function revealCardBatch(RevealedCard[] calldata _cards) external;

    /**
     * @notice Initializes a game
     * @param _data The details of the game
     */
    function initialize(InitializeGame calldata _data) external;

    /**
     * @notice Initializes multiple games
     * @param _data The details of multiple games
     */
    function initializeBatch(InitializeGame[] calldata _data) external;
}
