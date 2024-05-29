// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IntegrationTest} from "../Integration.t.sol";
import {Game} from "../../../src/Game.sol";
import {IRevealer} from "../../../src/interfaces/IRevealer.sol";

contract RevealCardTest is IntegrationTest {
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

    // function test_revealCardWithTheRightData() public {}
    //
    // function testFail_revealCardWithWrongData() public {}
    //
    // function testFail_revealCardDirectly() public {}
    //
    // function test_revealMultipleCards() public {}
    //
    // function testFail_unauthorizedRevealCard() public {}
    //
    // function testFail_revealGuessCardAsFreeReveal() public {}
    //
    // function testFail_revealFreeRevealCardAsGuessCard() public {}
    //
    // function test_revealCardShouldChangeCardsRevealedVariable() public {}
    //
    // function test_revealCardShouldNotChangeFreeRevealedVariable() public {}
    //
    // function test_revealCardShouldChangeTheCardsVariable() public {}
    //
    // function test_revealCardShouldChangeRevealedCardNumbersCountVariable() public {}
    //
    // function test_revealCardShouldTransferUSDTIfWon() public {}
    //
    // function test_revealCardShouldNotTransferUSDTIfLost() public {}
    //
    // function testFail_revealTheSameCardTwice() public {}
    //
    // function test_setMontShouldEmitEvents() public {}
}
