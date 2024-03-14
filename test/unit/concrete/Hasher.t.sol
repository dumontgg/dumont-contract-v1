// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test, console2} from "forge-std/Test.sol";

import {Hasher} from "../../../src/Hasher.sol";

contract HasherTest is Test {
    Hasher public h;

    function setUp() public {
        h = new Hasher();
    }

    function test_a() public {
        string memory salt = "346585ff4aa8ecdb13e6eac11ea7791419a37417";

        bytes32 serverHash = 0x787cb0cf264bebb50dcc5ceaa6537df1aecd059eb45756fc6e2524ab6191c26f;
        // console2.logBytes32(keccak256(abi.encodePacked('1Clubs', salt)));
        // first, server puts the value in the contract
        h.setHash(serverHash);

        // then the player comes and takes a guess
        h.takeGuess("1Clubs");

        console2.logBytes(abi.encodePacked("1Clubs"));
        console2.logBytes(abi.encodePacked("1Clubs", salt));
        console2.logBytes32(keccak256(abi.encodePacked("1Clubs", salt)));

        console2.logBytes(abi.encodePacked("2Clubs"));
        console2.logBytes(abi.encodePacked("2Clubs", salt));
        console2.logBytes32(keccak256(abi.encodePacked("2Clubs", salt)));

        // now server puts the right answer and the salt into the contract

        bool a = h.result("1Clubs", "346585ff4aa8ecdb13e6eac11ea7791419a37417");

        console2.logBool(a);
    }
}
