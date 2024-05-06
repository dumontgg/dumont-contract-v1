// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IGame {
    enum CardStatus {
        SECRETED,
        GUESSED,
        CLAIMED,
        LEAK_REQUESTED,
        REVEALED
    }

    struct Card {
        uint256 betAmount;
        uint256 totalAmount;
        uint256 guessedAt;
        uint256 revealedNumber;
        bool[13] guessedNumbers;
        bytes32 hash;
        CardStatus status;
        string revealedSalt;
    }

    event CardRevealed(uint256 indexed _index, uint256 indexed _number, string _salt);

    event PlayerGuessed(uint256 indexed _index, uint256 indexed _usdtAmount, bool[13] _guessedNumbers);

    event RevealFreeCardRequested(uint256 indexed _index, uint256 _timestamp);

    event CardClaimed(uint256 indexed _index, uint256 _timestamp);

    error CardIsNotSecret(uint256 _index);
    error MaximumLeaksRequested();

    error CardIsNotGuessed(uint256 _index);

    error CardIsNotLeakRequested(uint256 _index);

    error BetAmountIsLessThanMinimum();

    error BetAmountIsGreaterThanMaximum();

    error NotAuthorized(address _caller);

    error InvalidGameIndex();

    error GameIsUnlocked();

    error NotYetTimeToClaim(uint256 _index);

    error GameExpired();

    error GameIsLocked();

    error InvalidSalt(uint256 _index, uint256 _number, string _salt);
}
