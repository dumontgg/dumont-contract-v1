// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title Revealer Contract
 * @notice Manages the revelation of cards from multiple games
 */
interface IRevealer {
    struct RevealedCard {
        address game;
        uint256 index;
        uint256 number;
        string salt;
    }

    /**
     * @notice Emitted when a card is revealed
     * @param _revealer The address of the entity revealing the card
     * @param _game The address of the game from which the card is revealed
     * @param _index The index of the revealed card
     */
    event CardRevealed(address _revealer, address _game, uint256 _index);

    /**
     * @notice Reveals cards from multiple games
     * @param _cards The details of the revealed cards from multiple games
     */
    function revealBatch(RevealedCard[] calldata _cards) external;
}
