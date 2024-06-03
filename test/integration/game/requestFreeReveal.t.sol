// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IntegrationTest} from "../Integration.t.sol";
import {Game} from "../../../src/Game.sol";
import {IRevealer} from "../../../src/interfaces/IRevealer.sol";

contract RequestFreeReveal is IntegrationTest {
    enum CardStatus {
        SECRETED,
        GUESSED,
        CLAIMED,
        FREE_REVEAL_REQUESTED,
        REVEALED
    }

    Game public game;

    uint256 index = 0;

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

    function test_requestFreeReveal() public changeCaller(users.adam) {
        game.requestFreeRevealCard(index);

        assertEq(uint256(game.cards(index).status), uint256(CardStatus.FREE_REVEAL_REQUESTED));
    }

    // function testFail_requestFreeRevealMoreThanMaximum() public {}

    // function testFail_requestFreeRevealTwice() public {}
    //
    // function test_requestFreeRevealShouldEmitEvents() public {}
    //
    // function test_requestFreeRevealShouldEmitEvents() public {}
    //
    // function test_requestFreeRevealShouldChangeCardsFreeRevealedVariable() public {}
    //
    // function testFail_unauthorizedRequestFreeReveal() public {}
}
