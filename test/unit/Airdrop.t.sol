// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseTest} from "../Base.t.sol";
import {Airdrop} from "../../src/Airdrop.sol";
import {IAirdrop} from "../../src/interfaces/IAirdrop.sol";

contract AirdropTest is BaseTest {
    error OwnableUnauthorizedAccount(address account);

    Airdrop public airdrop;
    uint256 public initialAmount = 100e18;

    function setUp() public virtual override {
        BaseTest.setUp();

        deployContracts();

        vm.prank(users.adam);
        airdrop = new Airdrop(mont, initialAmount);

        mont.transfer(address(airdrop), initialAmount * 100);
    }

    function test_airdrop_deployment() public {
        assertEq(airdrop.owner(), users.adam);
    }

    function test_add_claimer() public {
        vm.prank(users.adam);
        airdrop.addClaimer(users.eve);
    }

    function test_add_claimer_should_emit_events() public {
        vm.prank(users.adam);

        vm.expectEmit(true, false, false, false);
        emit IAirdrop.ClaimerAdded(users.eve);
        airdrop.addClaimer(users.eve);
    }

    function test_add_claimers() public {
        vm.prank(users.adam);

        address[] memory claimers = new address[](3);
        claimers[0] = users.eve;
        claimers[1] = users.bob;
        claimers[2] = users.adam;

        airdrop.addClaimers(claimers);
    }

    function test_unauthorized_add_claimer_reverts() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, users.eve));

        vm.prank(users.eve);
        airdrop.addClaimer(users.eve);
    }

    function test_unauthorized_add_claimers_reverts() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, users.eve));

        address[] memory claimers = new address[](3);
        claimers[0] = users.eve;

        vm.prank(users.eve);
        airdrop.addClaimers(claimers);
    }

    function test_add_claimer_should_set_amount_in_mapping() public {
        vm.prank(users.adam);
        airdrop.addClaimer(users.eve);

        assertEq(airdrop.claimers(users.eve), initialAmount);
    }

    function test_set_new_claim_amount() public {
        vm.prank(users.adam);

        airdrop.setClaimAmount(initialAmount * 2);

        assertEq(airdrop.claimAmount(), initialAmount * 2);
    }

    function test_unauthorized_set_new_claim_amount_reverts() public {
        vm.prank(users.eve);

        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, users.eve));

        airdrop.setClaimAmount(initialAmount * 2);

        assertEq(airdrop.claimAmount(), initialAmount);
    }

    function test_new_claimers_added_use_the_new_claim_amount() public {
        vm.startPrank(users.adam);

        airdrop.addClaimer(users.eve);
        airdrop.setClaimAmount(initialAmount * 3);
        airdrop.addClaimer(users.bob);

        vm.stopPrank();

        assertEq(airdrop.claimers(users.eve), initialAmount);
        assertEq(airdrop.claimers(users.bob), initialAmount * 3);
    }

    function test_claim_airdrop() public {
        vm.prank(users.adam);
        airdrop.addClaimer(users.eve);

        uint256 montBefore = mont.balanceOf(users.eve);

        vm.prank(users.eve);
        airdrop.claim();

        uint256 montAfter = mont.balanceOf(users.eve);

        assertEq(montAfter, montBefore + initialAmount);
        assertEq(airdrop.totalMontClaimed(), initialAmount);
    }

    function test_claim_airdrop_should_set_the_claimers_amount_to_zero() public {
        vm.prank(users.adam);
        airdrop.addClaimer(users.eve);

        vm.prank(users.eve);
        airdrop.claim();

        assertEq(airdrop.claimers(users.eve), 0);
    }

    function test_not_eligible_claims_revert() public {
        vm.prank(users.eve);
        vm.expectRevert(abi.encodeWithSelector(IAirdrop.NotEligible.selector, users.eve));

        airdrop.claim();
    }

    function test_withdraw_remaining_mont() public {
        vm.prank(users.adam);
        airdrop.addClaimer(users.eve);

        uint256 montBefore = mont.balanceOf(address(airdrop));

        vm.prank(users.eve);
        airdrop.claim();

        uint256 montAfter = mont.balanceOf(address(airdrop));

        assertEq(montBefore, montAfter + initialAmount);
    }

    function test_unathorized_withdraw_call_reverts() public {
        vm.prank(users.eve);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, users.eve));

        airdrop.withdraw();
    }
}
