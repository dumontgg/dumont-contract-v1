// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseTest} from "../../Base.t.sol";
import {GameFactory} from "../../../src/GameFactory.sol";

contract GameFactoryTest is BaseTest {
    event GameFeeChanged(uint256 indexed _from, uint256 indexed _to);

    GameFactory public factory;

    function setUp() public override {
        BaseTest.setUp();

        deployContracts();

        factory = new GameFactory(usdt, vault, address(this), 10, 10, 10, 1e6);
    }

    function testOwner() public {
        assertEq(factory.owner(), address(this));
    }

    function testFailCallFromNotOwner2() public {
        vm.startPrank(users.adam);

        factory.setRevealer(msg.sender);

        vm.stopPrank();
    }

    function testFailCallFromNotOwner3() public {
        vm.startPrank(users.adam);

        factory.setGameDuration(222);

        vm.stopPrank();
    }

    function testFailCallFromNotOwner4() public {
        vm.startPrank(users.adam);

        factory.setClaimableAfter(222);

        vm.stopPrank();
    }

    function testFailCallFromNotOwner5() public {
        vm.startPrank(users.adam);

        factory.setMaxFreeReveals(222);

        vm.stopPrank();
    }

    function testGameCreationFeeEvent() public {
        vm.expectEmit(true, true, false, false);

        emit GameFeeChanged(1e6, 1e18);

        factory.setGameCreationFee(1e18);

        assertEq(factory.gameCreationFee(), 1e18);
    }

    function testCreateGame() public {
        // Adam has USDT
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee());

        assertEq(usdt.allowance(users.adam, address(factory)), factory.gameCreationFee());

        factory.createGame(address(0));

        assertEq(usdt.allowance(users.adam, address(factory)), 0);

        vm.stopPrank();
    }

    function testCreateGameStoresOnGame() public {
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee());

        (uint256 id, address game) = factory.createGame(address(0));

        assertEq(id, 0);
        assertEq(factory.games(0).gameCreatedAt, block.timestamp);
        assertEq(factory.games(0).gameAddress, game);
        assertEq(factory.games(0).player, users.adam);

        vm.stopPrank();
    }

    function testCreateGamesStoresAccordingly() public {
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

    function testChangeMaxFreeRevealsForNewGames() public {
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

    function testChangeGameCreationFeeForNewGames() public {
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

    function testChangeGameDurationForNewGames() public {
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

    function testChangeClaimableAfterForNewGames() public {
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

    function testSetReferralForNewGames() public {
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee());

        factory.createGame(users.eve);

        assertEq(factory.referrals(users.adam), users.eve);
        assertEq(factory.referrals(users.eve), address(0));
        assertEq(factory.referrerInvites(users.eve), 1);

        vm.stopPrank();
    }

    function testSetReferralsShouldIncrementReferrerInvites() public {
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

    function testFailSetReferralForSecondTime() public {
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee() * 2);

        factory.createGame(users.eve);
        factory.createGame(users.admin);

        vm.stopPrank();
    }

    function testFailSetReferralForSelf() public {
        vm.startPrank(users.adam);

        usdt.approve(address(factory), factory.gameCreationFee() * 2);

        factory.createGame(users.adam);

        vm.stopPrank();
    }
}
