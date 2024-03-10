// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {GameFactory} from "../src/GameFactory.sol";

contract GameFactoryTest is Test {
    GameFactory public gameFactory;

    function setUp() public {
        // gameFactory = new GameFactory(address(this), address(this));
    }
}
