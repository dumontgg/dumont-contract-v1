// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseTest} from "../Base.t.sol";
import {GameFactory} from "../../src/GameFactory.sol";

contract GameFactoryTest is BaseTest {
    event GameFeeChanged(uint256 indexed _from, uint256 indexed _to);

    error EnforcedPause();
    error OwnableUnauthorizedAccount(address _caller);
    error GameCreationFeeIsTooHigh(uint256 _newFee, uint256 _maxFee);

    GameFactory public factory = new GameFactory();

    function setUp() public override {
        BaseTest.setUp();

        deployContracts();

        factory.initialize(usdt, vault, address(this), 10, 10, 10, 1e6);
    }

    function test_owner() public {
        assertEq(factory.owner(), address(this));
    }

    function testFail_callFromNotOwner2() public {
        vm.startPrank(users.adam);

        factory.setRevealer(msg.sender);

        vm.stopPrank();
    }

    function testFail_callFromNotOwner3() public {
        vm.startPrank(users.adam);

        factory.setGameDuration(222);

        vm.stopPrank();
    }

    function testFail_callFromNotOwner4() public {
        vm.startPrank(users.adam);

        factory.setClaimableAfter(222);

        vm.stopPrank();
    }

    function testFail_callFromNotOwner5() public {
        vm.startPrank(users.adam);

        factory.setMaxFreeReveals(222);

        vm.stopPrank();
    }

    function test_gameCreationFeeEvent() public {
        vm.expectEmit(true, true, false, false);

        uint256 newFee = 10e6;

        emit GameFeeChanged(1e6, newFee);

        factory.setGameCreationFee(newFee);

        assertEq(factory.gameCreationFee(), newFee);
    }

    function testFail_calllingGameCreationFeeGreaterThanMaximumShouldRevert() public {
        uint256 newFee = 200e6;
        factory.setGameCreationFee(newFee);
    }

    function test_createGame() public {
        // Adam has USDT
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee());

        assertEq(usdt.allowance(users.adam, address(factory)), factory.gameCreationFee());

        factory.createGame(address(0));

        assertEq(usdt.allowance(users.adam, address(factory)), 0);

        vm.stopPrank();
    }

    function test_createGameStoresOnGame() public {
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee());

        (uint256 id, address game) = factory.createGame(address(0));

        assertEq(id, 0);
        assertEq(factory.games(0).gameCreatedAt, block.timestamp);
        assertEq(factory.games(0).gameAddress, game);
        assertEq(factory.games(0).player, users.adam);

        vm.stopPrank();
    }

    function test_createGamesStoresAccordingly() public {
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee() * 4);

        (uint256 id0,) = factory.createGame(address(0));
        (uint256 id1,) = factory.createGame(address(0));
        (uint256 id2,) = factory.createGame(address(0));
        (uint256 id3,) = factory.createGame(address(0));

        assertEq(id0, 0);
        assertEq(id1, 1);
        assertEq(id2, 2);
        assertEq(id3, 3);

        assertEq(factory.userGames(users.adam), 4);

        vm.stopPrank();
    }

    function test_changeMaxFreeRevealsForNewGames() public {
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee() * 4);

        (uint256 id0,) = factory.createGame(address(0));

        assertEq(factory.games(id0).maxFreeReveals, 10);

        vm.stopPrank();

        factory.setMaxFreeReveals(5);

        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee() * 4);

        (uint256 id1,) = factory.createGame(address(0));

        assertEq(factory.games(id1).maxFreeReveals, 5);

        vm.stopPrank();

        assertEq(factory.userGames(users.adam), 2);
    }

    function test_changeGameCreationFeeForNewGames() public {
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee());

        factory.createGame(address(0));

        assertEq(usdt.allowance(users.adam, address(factory)), 0);

        vm.stopPrank();

        factory.setGameCreationFee(2e6);

        vm.startPrank(users.adam);

        usdt.approve(address(factory), 2e6);

        assertEq(usdt.allowance(users.adam, address(factory)), 2e6);

        factory.createGame(address(0));

        assertEq(usdt.allowance(users.adam, address(factory)), 0);

        vm.stopPrank();
    }

    function test_changeGameDurationForNewGames() public {
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee());

        (uint256 id0,) = factory.createGame(address(0));

        assertEq(factory.games(id0).gameDuration, 10);

        vm.stopPrank();

        factory.setGameDuration(1 days);

        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee());

        (uint256 id1,) = factory.createGame(address(0));

        assertEq(factory.games(id1).gameDuration, 1 days);

        vm.stopPrank();
    }

    function test_changeClaimableAfterForNewGames() public {
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee());

        (uint256 id0,) = factory.createGame(address(0));

        assertEq(factory.games(id0).claimableAfter, 10);

        vm.stopPrank();

        factory.setClaimableAfter(2 days);

        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee());

        (uint256 id1,) = factory.createGame(address(0));

        assertEq(factory.games(id1).claimableAfter, 2 days);

        vm.stopPrank();
    }

    function test_setReferralForNewGames() public {
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee());

        factory.createGame(users.eve);

        assertEq(factory.referrals(users.adam), users.eve);
        assertEq(factory.referrals(users.eve), address(0));
        assertEq(factory.referrerInvites(users.eve), 1);

        vm.stopPrank();
    }

    function test_setReferralsShouldIncrementReferrerInvites() public {
        // Set eve as referrer for adam
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee());

        factory.createGame(users.eve);

        vm.stopPrank();

        // Set eve as referrer for admin
        vm.startPrank(users.admin);

        usdt.approve(address(factory), factory.gameCreationFee());

        factory.createGame(users.eve);

        vm.stopPrank();

        // Set eve as referrer for bob
        vm.startPrank(users.bob);

        usdt.approve(address(factory), factory.gameCreationFee());

        factory.createGame(users.eve);

        vm.stopPrank();

        assertEq(factory.referrerInvites(users.eve), 3);
    }

    function test_setReferralForSecondTimeShouldNotChangeTheReferrer() public {
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee() * 2);

        factory.createGame(users.eve);
        factory.createGame(users.admin);

        vm.stopPrank();

        assertEq(factory.referrals(users.adam), users.eve);
    }

    function test_setReferralForSelfShouldNotChangeTheReferrer() public {
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee() * 2);

        factory.createGame(users.adam);

        vm.stopPrank();

        assertEq(factory.referrals(users.adam), address(0));
    }

    function test_createNewGameWhenPauseShouldRevert() public {
        factory.pause();

        vm.prank(users.adam);
        vm.expectRevert(abi.encodeWithSelector(EnforcedPause.selector));

        factory.createGame(users.adam);
    }

    function test_unauthorizedCallsToPauseShouldRevert() public {
        vm.prank(users.adam);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, users.adam));

        factory.pause();
    }

    function test_unauthorizedCallsToUnPauseShouldRevert() public {
        factory.pause();

        vm.prank(users.adam);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, users.adam));

        factory.unpause();
    }
}
