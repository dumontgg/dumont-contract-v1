// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IntegrationTest} from "../Integration.t.sol";
import {Game} from "../../../src/Game.sol";
import {IRevealer} from "../../../src/interfaces/IRevealer.sol";

contract ClaimWinTest is IntegrationTest {
    Game public game;

    uint256 index = 0;
    uint256 amounts = 1;
    uint256 betAmount = 20e6;

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

        vm.startPrank(users.adam);

        usdt.approve(address(gameFactory), 100e6);

        game.guessCard(index, betAmount, amounts);

        vm.stopPrank();
    }

    // function test_claimWinAfterTheTime() public {}

    // function testFail_claimWinShouldFailIfCalledBefore() public {}
    //
    // function test_claimWinShouldEmitEvents() public {}
    //
    // function test_claimWinShouldFailIfCardIsNotGuessed() public {}
    //
    // function test_claimWinShouldNotSetMontRewards() public {}
}
