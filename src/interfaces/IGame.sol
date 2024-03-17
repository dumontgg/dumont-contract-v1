// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IGame {
    enum CardStatus {
        HIDDEN,
        GUESSED,
        CLAIMED,
        FREE_REVEALE_REQUESTED,
        REVEALED,
        FREE_REVEALED
    }

    struct Card {
        bytes hashed;
        uint256 betAmount;
        uint256 totalAmount;
        bool[13] guessedNumbers;
        CardStatus status;
        uint256 guessedAt;
        string revealedSalt;
        uint256 revealedNumber;
    }

    event CardRevealed(uint256 _index, uint256 _number, string _salt);

    event PlayerGuessed(uint256 _index, bool[13] _guessedNumbers, uint256 _usdtAmount);

    event RevealFreeCardRequested(uint256 _index, uint256 _timestamp);

    event CardClaimed(uint256 _index, uint256 _timestamp);

    error CardIsNotHidden(uint256 _index);

    error CardIsNotGuessed(uint256 _index);

    error BetAmountIsLessThanMinimum();

    error BetAmountIsGreaterThanMaximum();

    error NotAuthorized(address _caller);

    error InvalidGameIndex();

    error GameIsUnlocked();

    error NotYetTimeToClaim(uint256 _index);

    error GameIsLocked();

    error CardIsNotFreeRevealed();
}
