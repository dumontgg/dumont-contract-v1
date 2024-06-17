// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {BaseTest} from "../Base.t.sol";
import {Vault} from "../../src/Vault.sol";
import {Burner} from "../../src/Burner.sol";
import {GameFactory} from "../../src/GameFactory.sol";
import {MontRewardManager} from "../../src/MontRewardManager.sol";

contract VaultTest is BaseTest {
    uint256 private constant GAME_CREATION_FEE = 1e18;
    uint256 private constant MINIMUM_BET_ = 1e18;

    function setUp() public virtual override {
        BaseTest.setUp();

        vm.prank(users.admin);
        vault = new Vault(
            mont,
            usdt,
            Burner(address(0x00)),
            GameFactory(address(0x00)),
            MontRewardManager(address(0x00)),
            GAME_CREATION_FEE
        );
    }

    function test_owner() public {
        assertEq(vault.owner(), users.admin);
    }

    function test_deposit() public changeCaller(users.admin) {
        uint256 amount = 100e6;

        usdt.approve(address(vault), amount);

        uint256 balanceBefore = usdt.balanceOf(address(vault));

        vault.deposit(amount);

        uint256 balanceAfter = usdt.balanceOf(address(vault));

        assertEq(balanceBefore + amount, balanceAfter);
    }

    function testFail_depositNotAuthorized() public {
        uint256 amount = 100e6;

        usdt.approve(address(vault), amount);

        uint256 balanceBefore = usdt.balanceOf(address(vault));

        vault.deposit(amount);

        uint256 balanceAfter = usdt.balanceOf(address(vault));

        assertEq(balanceBefore + amount, balanceAfter);
    }

    function test_depositAndWithdraw() public changeCaller(users.admin) {
        uint256 amount = 100e6;

        usdt.approve(address(vault), amount);

        uint256 vaultBalanceBefore = usdt.balanceOf(address(vault));

        vault.deposit(amount);

        uint256 vaultBalanceAfter = usdt.balanceOf(address(vault));

        assertEq(vaultBalanceBefore + amount, vaultBalanceAfter);

        uint256 adminBalanceBefore = usdt.balanceOf(users.admin);

        vault.withdraw(address(usdt), amount, users.admin);

        uint256 adminBalanceAfter = usdt.balanceOf(users.admin);
        uint256 vaultBalanceAfterWithdraw = usdt.balanceOf(address(vault));

        assertEq(vaultBalanceBefore, vaultBalanceAfterWithdraw);
        assertEq(adminBalanceBefore + amount, adminBalanceAfter);
    }

    function test_minimumBetAmount() public changeCaller(users.admin) {
        vault.setMinimumBetAmount(2e6);

        assertEq(vault.getMinimumBetAmount(), 2e6);
    }

    function test_maximumBetAmount() public changeCaller(users.admin) {
        uint256 amount = 100e6;

        usdt.approve(address(vault), amount);

        vault.deposit(amount);

        assertEq(vault.getMaximumBetAmount(), 2e6);
    }

    function test_withdrawETH() public changeCaller(users.admin) {
        (bool success,) = address(vault).call{value: 1e18}("");

        assertEq(success, true);
        assertEq(address(vault).balance, 1e18);

        uint256 balanceBefore = users.bob.balance;

        vault.withdrawETH(users.bob);

        uint256 balanceAfter = users.bob.balance;

        assertEq(balanceBefore + 1e18, balanceAfter);
    }

    function testFail_withdrawETHNotAdminCalling() public changeCaller(users.bob) {
        (bool success,) = address(vault).call{value: 1e18}("");

        assertEq(success, true);
        assertEq(address(vault).balance, 1e18);

        uint256 balanceBefore = users.bob.balance;

        vault.withdrawETH(users.bob);

        uint256 balanceAfter = users.bob.balance;

        assertEq(balanceBefore + 1e18, balanceAfter);
    }
}
