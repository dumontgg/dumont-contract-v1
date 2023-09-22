// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract Hasher {
    bytes32 public value;
    string public guess;
    string public salt;

    function setHash(bytes32 _value) external {
        value = _value;
    }

    function takeGuess(string memory _guessValue) external {
        guess = _guessValue;
    }

    function result(string memory _card, string memory _salt) external returns (bool) {
        salt = _salt;

        bytes32 generate = keccak256(abi.encodePacked(_card, _salt));

        require(value == generate);

        bytes32 userGuess = keccak256(abi.encodePacked(guess, _salt));

        if (userGuess == value) {
            return true;
        }

        return false;
    }
}
