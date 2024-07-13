// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseTest} from "../Base.t.sol";
import {TaxBasedLocker} from "../../src/TaxBasedLocker.sol";

contract TaxBasedLockerTest is BaseTest {
    event Initialized();
    event Withdrawn(address indexed owner, uint256 withdrawableAmount);
    event Burned(address indexed owner, uint256 burnableAmount);

    error InvalidAmount();
    error AlreadyInitialized();
    error OwnableUnauthorizedAccount(address _caller);

    TaxBasedLocker locker;

    uint256 lockAmount = 100e18;
    uint256 lockPeriod = 10 * 365 days; // 10 years

    function setUp() public override {
        BaseTest.setUp();

        vm.startPrank(users.admin);

        locker = new TaxBasedLocker(mont, lockPeriod);

        mont.approve(address(locker), lockAmount);

        vm.stopPrank();
    }

    function test_initialize() public {
        vm.prank(users.admin);

        locker.initialize(lockAmount);

        assertEq(locker.lockedAmount(), lockAmount);

        assertEq(mont.balanceOf(address(locker)), lockAmount);
    }

    function test_alreadyInitializedShouldRevert()
        public
        changeCaller(users.admin)
    {
        locker.initialize(lockAmount);

        vm.expectRevert(AlreadyInitialized.selector);

        locker.initialize(lockAmount);
    }

    function test_withdrawEarly() public changeCaller(users.admin) {
        locker.initialize(lockAmount);

        // Fast forward 5 years
        vm.warp(block.timestamp + (5 * 365 days));

        uint256 withdrawableAmount = locker.calculateWithdrawableAmount();
        uint256 burnableAmount = lockAmount - withdrawableAmount;

        assertEq(withdrawableAmount, lockAmount / 2);

        uint256 adminBalanceBefore = mont.balanceOf(users.admin);
        uint256 totalSupplyBefore = mont.totalSupply();

        locker.withdraw();

        uint256 totalSupplyAfter = mont.totalSupply();
        uint256 adminBalanceAfter = mont.balanceOf(users.admin);

        assertEq(adminBalanceAfter, adminBalanceBefore + withdrawableAmount);
        assertEq(mont.balanceOf(address(locker)), 0);
        assertEq(totalSupplyAfter, totalSupplyBefore - burnableAmount);
    }

    function test_withdrawAfterLockPeriod() public changeCaller(users.admin) {
        locker.initialize(lockAmount);

        // Fast forward 10 years
        vm.warp(block.timestamp + lockPeriod);

        uint256 withdrawableAmount = locker.calculateWithdrawableAmount();

        assertEq(withdrawableAmount, lockAmount);

        uint256 adminBalanceBefore = mont.balanceOf(users.admin);
        uint256 totalSupplyBefore = mont.totalSupply();

        locker.withdraw();

        uint256 totalSupplyAfter = mont.totalSupply();
        uint256 adminBalanceAfter = mont.balanceOf(users.admin);

        assertEq(adminBalanceAfter, adminBalanceBefore + lockAmount);
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }

    function test_emitEvents() public changeCaller(users.admin) {
        vm.expectEmit(true, true, false, true);
        emit Initialized();
        locker.initialize(lockAmount);

        vm.warp(block.timestamp + (5 * 365 days));

        uint256 withdrawableAmount = locker.calculateWithdrawableAmount();
        uint256 burnableAmount = lockAmount - withdrawableAmount;

        vm.expectEmit(true, true, false, true);
        emit Withdrawn(users.admin, withdrawableAmount);

        vm.expectEmit(true, true, false, true);
        emit Burned(users.admin, burnableAmount);

        locker.withdraw();
    }

    function test_callingInitializeWithLockedAmountSetToZeroShouldRevert()
        public
    {
        vm.prank(users.admin);

        vm.expectRevert(abi.encodeWithSelector(InvalidAmount.selector));
        locker.initialize(0);
    }

    function test_onlyOwnerCanInitialize() public {
        vm.prank(users.bob);

        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUnauthorizedAccount.selector,
                users.bob
            )
        );
        locker.initialize(lockAmount); // This should fail
    }

    function test_onlyOwnerCanWithdraw() public {
        vm.prank(users.admin);
        locker.initialize(lockAmount);

        // Fast forward 5 years
        vm.warp(block.timestamp + (5 * 365 days));

        vm.prank(users.bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUnauthorizedAccount.selector,
                users.bob
            )
        );
        locker.withdraw(); // This should fail
    }
}
