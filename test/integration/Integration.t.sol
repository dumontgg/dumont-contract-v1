// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {console2} from "forge-std/console2.sol";

import {BaseTest} from "../Base.t.sol";
import {RandomDeck} from "../utils/RandomDeck.sol";

abstract contract IntegrationTest is BaseTest, RandomDeck {
    function setUp() public virtual override {
        BaseTest.setUp();

        deployContracts();

        setCards();

        vm.startPrank(users.admin);

        usdt.approve(address(vault), type(uint256).max);
        vault.deposit(100_000e6);

        assertEq(usdt.balanceOf(address(vault)), 100_000e6);

        console2.log("ADMIN MONT BALANCE: %s", mont.balanceOf(users.admin));

        mont.transfer(address(montRewardManager), 10_000_000e18);

        vm.stopPrank();
    }
}
