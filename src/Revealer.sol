// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {Game} from "./Game.sol";
import {IRevealer} from "./interfaces/IRevealer.sol";

contract Revealer is AccessControl, IRevealer {
    bytes32 public constant REVEALER_ROLE = keccak256("REVEALER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Reveals
     * @dev Only games that the reveal is this address can be called here. Cards can also be 
      from different games.
     * @param _cards The details of the revealed cards from multiple games
     */
    function revealBatch(
        RevealedCard[] calldata _cards
    ) external onlyRole(REVEALER_ROLE) {
        for (uint256 i = 0; i < _cards.length; ++i) {
            Game game = Game(_cards[i].game);

            game.revealCard(_cards[i].index, _cards[i].number, _cards[i].salt);

            emit CardRevealed(msg.sender, _cards[i].game, _cards[i].index);
        }
    }
}
