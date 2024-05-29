// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test, console2} from "forge-std/Test.sol";

contract HasherTest is Test {
    function setUp() public {}

    function test_a() public pure {
        // string memory salt = "346585ff4aa8ecdb13e6eac11ea7791419a37417";
        //
        uint256 number = 5;
        bytes32 serverHash = 0x7cc8c1f06ffb28b503d45b211245228a75ddafd988e199e2f0ef6569556b193c;
        // console2.logBytes32(keccak256(abi.encodePacked(number, serverHash)));
        // console2.logBytes(abi.encodePacked(number, serverHash));
        // console2.logBytes32(keccak256(abi.encodePacked(number, serverHash)));

        // // first, server puts the value in the contract
        // h.setHash(serverHash);
        //
        // // then the player comes and takes a guess
        // h.takeGuess("1Clubs");
        //
        // console2.logBytes(abi.encodePacked("1Clubs"));
        // console2.logBytes(abi.encodePacked("1Clubs", salt));
        // console2.logBytes32(keccak256(abi.encodePacked("1Clubs", salt)));
        //
        // console2.logBytes(abi.encodePacked("2Clubs"));
        // console2.logBytes(abi.encodePacked("2Clubs", salt));
        // console2.logBytes32(keccak256(abi.encodePacked("2Clubs", salt)));
        //
        // // now server puts the right answer and the salt into the contract
        //
        // bool a = h.result("1Clubs", "346585ff4aa8ecdb13e6eac11ea7791419a37417");
        //
        // console2.logBool(a);
    }
}
