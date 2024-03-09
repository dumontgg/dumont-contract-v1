// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRevealer {
    struct RevealedCard {
        address game;
        uint256 index;
        uint256 number;
        string salt;
    }

    event CardRevealed(address _revealer, address _game, uint256 _index);
}
