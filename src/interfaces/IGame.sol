// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// todo:
interface IGame {
    enum CardStatus {
        SECRETED,
        GUESSED,
        CLAIMED,
        FREE_REVEAL_REQUESTED,
        REVEALED
    }

    struct Card {
        uint256 betAmount;
        uint256 totalAmount;
        uint256 guessedAt;
        uint256 revealedNumber;
        uint256 guessedNumbers;
        bytes32 hash;
        bytes32 revealedSalt;
        CardStatus status;
    }

    event CardRevealed(uint256 indexed _index, uint256 indexed _number, bytes32 _salt);

    event PlayerGuessed(uint256 indexed _index, uint256 indexed _usdtAmount, uint256 _guessedNumbers);

    event RevealFreeCardRequested(uint256 indexed _index, uint256 _timestamp);

    event CardClaimed(uint256 indexed _index, uint256 _timestamp);

    error CardIsNotSecret(uint256 _index);
    error MaximumFreeRevealsRequested();

    error CardIsNotGuessed(uint256 _index);

    error CardStatusIsNotFreeRevealRequested(uint256 _index);

    error BetAmountIsLessThanMinimum();

    error BetAmountIsGreaterThanMaximum();

    error NotAuthorized(address _caller);

    error InvalidGameIndex();

    error InvalidNumbersGuessed(uint256 _guessedNumbers);

    error NotYetTimeToClaim(uint256 _index);

    error GameExpired();

    error InvalidSalt(uint256 _index, uint256 _number, bytes32 _salt);

    // TODO: add fucntions

    function cards(uint256 _index) external view returns (Card memory);
}
