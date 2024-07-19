// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseTest} from "../Base.t.sol";
import {RandomDeck} from "../utils/RandomDeck.sol";

abstract contract IntegrationTest is BaseTest, RandomDeck {
    function setUp() public virtual override {
        BaseTest.setUp();

        deployContracts();

        setCards(users.adam);

        vm.startPrank(users.admin);

        usdt.approve(address(vault), type(uint256).max);
        vault.deposit(100_000e6);

        assertEq(usdt.balanceOf(address(vault)), 100_000e6);

        mont.transfer(address(montRewardManager), 10_000_000e18);

        vm.stopPrank();
    }
}
