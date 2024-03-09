// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IGame {
    event CardRevealed(uint256 _index, uint256 _number, string _salt);
    event PlayerGuessed(uint256 _index, uint256[] _number, uint256 _usdtAmount);

    error AlreadyGuessed(uint256 _index, uint256[] _guessedNumbers);
    error BetAmountIsLessThanMinimum();
    error BetAmountIsGreaterThanMaximum();
    error NotAuthorized();
    error InvalidGameIndex();
    error GameIsUnlocked();
    error GameIsLocked();

    struct Card {
        bytes hashed;
        bool isGuessed;
        uint256 betAmount;
        string revealedSalt;
        uint256 revealedNumber;
        uint256[] guessedNumbers;
    }
}
