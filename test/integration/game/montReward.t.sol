// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IntegrationTest} from "../Integration.t.sol";
import {Game} from "../../../src/Game.sol";
import {IRevealer} from "../../../src/interfaces/IRevealer.sol";

contract MontRewardTest is IntegrationTest {
    Game public game;

    function setUp() public virtual override {
        IntegrationTest.setUp();

        assertEq(usdt.balanceOf(address(vault)), 100_000e6);

        vm.startPrank(users.adam);

        usdt.approve(address(gameFactory), 100e6);
        (, address game0) = gameFactory.createGame(address(0));

        game = Game(game0);

        vm.stopPrank();

        vm.startPrank(users.server1);

        IRevealer.InitializeGame memory params = IRevealer.InitializeGame({game: address(game), hashedDeck: deck});

        revealer.initialize(params);

        vm.stopPrank();
    }

    // function test_revealShouldSetMontRewards() public {}
    //
    // function test_revealShouldSetLessMontRewardsIfLost() public {}
    //
    // function test_revealShouldSetMontToReferrer() public {}
    //
    // function test_revealShouldSetMoreMontIfReferrerIsSet() public {}
    //
    // function test_revealShouldSetMoreMontIfReferrerIsSet() public {}
    //
    // function test_claimMontRewards() public {}
    //
    // function testFail_claimMontsUnauthorized() public {}
    //
    // function test_setMontShouldEmitEvents() public {}
}
