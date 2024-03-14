// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IGame {
    struct Card {
        uint256 betAmount;
        uint256 revealedNumber;
        uint256[] guessedNumbers;
        uint256 guessedAt;
        bytes hashed;
        bool isGuessed;
        bool isFreeRevealed;
        string revealedSalt;
    }

    event CardRevealed(uint256 _index, uint256 _number, string _salt);
    event PlayerGuessed(uint256 _index, uint256[] _number, uint256 _usdtAmount);

    error AlreadyGuessed(uint256 _index, uint256[] _guessedNumbers);
    error BetAmountIsLessThanMinimum();
    error BetAmountIsGreaterThanMaximum();
    error NotAuthorized();
    error InvalidGameIndex();
    error GameIsUnlocked();
    error GameIsLocked();
}
