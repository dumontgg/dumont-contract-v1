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
     * @notice Reveals cards from multiple games
     * @param _cards The details of the revealed cards from multiple games
     */
    function revealBatch(RevealedCard[] calldata _cards) external onlyRole(REVEALER_ROLE) {
        for (uint256 i = 0; i < _cards.length; ++i) {
            Game game = Game(_cards[i].game);

            game.revealCard(_cards[i].index, _cards[i].number, _cards[i].salt);

            emit CardRevealed(msg.sender, _cards[i].game, _cards[i].index);
        }
    }
}
