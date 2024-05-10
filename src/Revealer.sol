// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {Game} from "./Game.sol";
import {IRevealer} from "./interfaces/IRevealer.sol";

/**
 * @title Revealer Contract
 * @notice Manages the revelation of cards from multiple games
 * @dev Only addresses with the REVEALER_ROLE can call the revealBatch function
 */
contract Revealer is AccessControl, IRevealer {
    bytes32 public constant REVEALER_ROLE = keccak256("REVEALER_ROLE");

    /**
     * @notice Initializes the contract and grants the default admin role to the deployer
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Reveals a card
     * @param _card The details of the revealed card
     */
    function revealCard(RevealedCard calldata _card) external onlyRole(REVEALER_ROLE) {
        _revealCard(_card);
    }

    /**
     * @notice Reveals multiple cards from a single or different games
     * @param _cards The details of the revealed cards
     */
    function revealCardBatch(RevealedCard[] calldata _cards) external onlyRole(REVEALER_ROLE) {
        for (uint256 i = 0; i < _cards.length; ++i) {
            _revealCard(_cards[i]);
        }
    }

    /**
     * @notice Initializes a game
     * @param _data The details of the game
     */
    function initialize(InitializeGame calldata _data) external onlyRole(REVEALER_ROLE) {
        _initialize(_data);
    }

    /**
     * @notice Initializes multiple games
     * @param _data The details of multiple games
     */
    function initializeBatch(InitializeGame[] calldata _data) external onlyRole(REVEALER_ROLE) {
        for (uint256 i = 0; i < _data.length; ++i) {
            _initialize(_data[i]);
        }
    }

    /**
     * @notice Calls the game contract and initializes it
     * @param _data The hashed deck of the game
     */
    function _initialize(InitializeGame calldata _data) private {
        Game game = Game(_data.game);

        game.initialize(_data.hashedDeck);

        emit GameInitialized(msg.sender, _data.game);
    }

    /**
     * @notice Calls the game contract and reveals a secreted card
     * @param _card The details of the hashed card
     */
    function _revealCard(RevealedCard calldata _card) private {
        Game game = Game(_card.game);

        game.revealCard(_card.index, _card.number, _card.salt);

        emit CardRevealed(msg.sender, _card.game, _card.index);
    }
}
