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

    function revealBatch(RevealedCard[] calldata _cards) external onlyRole(REVEALER_ROLE) {
        for (uint256 i = 0; i < _cards.length; ++i) {
            Game game = Game(_cards[i].gameAddress);

            game.revealCard(_cards[i].cardIndex, _cards[i].cardNumber, _cards[i].salt);

            emit CardRevealed(msg.sender, _cards[i].gameAddress, _cards[i].cardIndex);
        }
    }
}
