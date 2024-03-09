// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRevealer {
    struct RevealedCard {
        address gameAddress;
        uint256 cardIndex;
        uint256 cardNumber;
        string salt;
    }

    event CardRevealed(address _revealer, address _game, uint256 _index);
}
