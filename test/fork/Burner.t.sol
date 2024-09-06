// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Burner} from "../../src/Burner.sol";
import {ForkTest} from "./Fork.t.sol";
import {SWAP_ROUTER, SHIBA, USDT} from "./Addresses.t.sol";

contract BurnerTest is ForkTest {
    event MONTTokensBurned(
        uint256 indexed _usdcAmount,
        uint256 indexed _montAmount
    );

    error NotEnoughUSDC();
    error OwnableUnauthorizedAccount(address account);

    address public poolAddress;
    Burner public burnerContract;

    function setUp() public override {
        ForkTest.setUp();

        vm.startPrank(users.admin);
        burnerContract = new Burner();
        burnerContract.initialize(SHIBA, USDT, SWAP_ROUTER, 3000);
        vm.stopPrank();

        deal(address(USDT), users.admin, 100_000_000e6);
        deal(address(SHIBA), users.admin, 100_000_000e18);
    }

    function test_depositUSDCAndBurn() public changeCaller(users.admin) {
        USDT.transfer(address(burnerContract), 1_000e6);

        assertEq(USDT.balanceOf(address(burnerContract)), 1_000e6);

        burnerContract.burnTokens(0, block.timestamp);
    }

    function test_callingBurnTokensFromUnauthorizedAccountsShouldrevert()
        public
        changeCaller(users.eve)
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUnauthorizedAccount.selector,
                users.eve
            )
        );

        burnerContract.burnTokens(0, block.timestamp);
    }

    function test_burnTokensShouldRevertIfThereIsZeroTokens()
        public
        changeCaller(users.admin)
    {
        vm.expectRevert(abi.encodeWithSelector(NotEnoughUSDC.selector));

        burnerContract.burnTokens(0, block.timestamp);
    }

    function test_burnTokensShouldEmitEvents()
        public
        changeCaller(users.admin)
    {
        USDT.transfer(address(burnerContract), 1_000e6);

        vm.expectEmit(true, false, false, false);

        emit MONTTokensBurned(1_000e6, 0);
        burnerContract.burnTokens(0, block.timestamp);
    }

    function test_burnTokensShouldDecreaseTheTotalSupplyOfMONTTokens()
        public
        changeCaller(users.admin)
    {
        uint256 totalSupplyBefore = SHIBA.totalSupply();

        USDT.transfer(address(burnerContract), 1_000e6);
        burnerContract.burnTokens(0, block.timestamp);

        uint256 totalSupplyAfter = SHIBA.totalSupply();

        assert(totalSupplyAfter < totalSupplyBefore);
    }
}
