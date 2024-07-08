// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Burner} from "../../src/Burner.sol";
import {ForkTest} from "./Fork.t.sol";
import {SWAP_ROUTER, SHIBA, USDC} from "./Addresses.t.sol";

contract BurnerTest is ForkTest {
    event MONTTokensBurned(uint256 indexed _usdtAmount, uint256 indexed _montAmount);

    error NotEnoughUSDT();
    error OwnableUnauthorizedAccount(address account);

    address public poolAddress;
    Burner public burnerContract;

    function setUp() public override {
        ForkTest.setUp();

        vm.prank(users.admin);
        burnerContract = new Burner(SHIBA, USDC, SWAP_ROUTER, 3000);

        deal(address(USDC), users.admin, 100_000_000e6);
        deal(address(SHIBA), users.admin, 100_000_000e18);
    }

    function test_depositUSDTAndBurn() public changeCaller(users.admin) {
        USDC.transfer(address(burnerContract), 1_000e6);

        assertEq(USDC.balanceOf(address(burnerContract)), 1_000e6);

        burnerContract.burnTokens(0);
    }

    function test_callingBurnTokensFromUnauthorizedAccountsShouldrevert() public changeCaller(users.eve) {
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, users.eve));

        burnerContract.burnTokens(0);
    }

    function test_burnTokensShouldRevertIfThereIsZeroTokens() public changeCaller(users.admin) {
        vm.expectRevert(abi.encodeWithSelector(NotEnoughUSDT.selector));

        burnerContract.burnTokens(0);
    }

    function test_burnTokensShouldEmitEvents() public changeCaller(users.admin) {
        USDC.transfer(address(burnerContract), 1_000e6);

        vm.expectEmit(true, false, false, false);

        emit MONTTokensBurned(1_000e6, 0);
        burnerContract.burnTokens(0);
    }

    function test_burnTokensShouldDecreaseTheTotalSupplyOfMONTTokens() public changeCaller(users.admin) {
        uint256 totalSupplyBefore = SHIBA.totalSupply();

        USDC.transfer(address(burnerContract), 1_000e6);
        burnerContract.burnTokens(0);

        uint256 totalSupplyAfter = SHIBA.totalSupply();

        assert(totalSupplyAfter < totalSupplyBefore);
    }
}
