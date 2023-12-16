// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IGame {
    struct Card {
        bytes hashed;
        // why bool? can't we use 256
        bool isInitialized;
        // why bool? can't we use 256
        bool isGuessed;
        // why uint8? can't we use 256
        uint8 guessedNumber;
        // why uint8? can't we use 256
        uint8 revealedNumber;
        string revealedSalt;
    }
}
