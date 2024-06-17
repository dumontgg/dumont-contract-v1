// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IntegrationTest} from "../Integration.t.sol";
import {Game} from "../../../src/Game.sol";
import {IRevealer} from "../../../src/interfaces/IRevealer.sol";

contract RequestFreeReveal is IntegrationTest {
    event RevealFreeCardRequested(uint256 indexed _index, uint256 _timestamp);

    error MaximumFreeRevealsRequested();
    error NotAuthorized(address _caller);
    error CardIsNotSecret(uint256 _index);

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

    function test_revertIfRequestFreeRevealIsCalledMoreThanMaximum() public changeCaller(users.adam) {
        assertEq(game.maxFreeReveals(), gameFactory.maxFreeReveals());

        // will run maxFreeReveals + 1 times
        for (uint256 i = 0; i <= game.maxFreeReveals(); i++) {
            if (i == game.maxFreeReveals()) {
                vm.expectRevert(abi.encodeWithSelector(MaximumFreeRevealsRequested.selector));
            }

            game.requestFreeRevealCard(i);
        }
    }

    function test_revertIfRequestFreeRevealIsCalledTwiceOnTheSameIndex() public changeCaller(users.adam) {
        game.requestFreeRevealCard(0);

        vm.expectRevert(abi.encodeWithSelector(CardIsNotSecret.selector, 0));

        game.requestFreeRevealCard(0);
    }

    function test_requestFreeRevealShouldEmitEvents() public changeCaller(users.adam) {
        vm.expectEmit(true, true, false, false);

        emit RevealFreeCardRequested(index, block.timestamp);

        game.requestFreeRevealCard(index);
    }

    function test_requestFreeRevealShouldChangeCardsFreeRevealedVariable() public changeCaller(users.adam) {
        game.requestFreeRevealCard(index);

        assertEq(uint256(game.cards(index).status), uint256(CardStatus.FREE_REVEAL_REQUESTED));
    }

    function test_revertIfUnauthorizedCallerCalledRequestFreeReveal() public {
        vm.startPrank(users.eve);

        vm.expectRevert(abi.encodeWithSelector(NotAuthorized.selector, users.eve));

        game.requestFreeRevealCard(index);

        vm.stopPrank();
    }
}
