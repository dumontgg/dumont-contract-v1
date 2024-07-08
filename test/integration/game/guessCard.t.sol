// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IntegrationTest} from "../Integration.t.sol";
import {Game} from "../../../src/Game.sol";
import {IRevealer} from "../../../src/interfaces/IRevealer.sol";

contract GuessCardTest is IntegrationTest {
    Game public game;

    function setUp() public virtual override {
        IntegrationTest.setUp();

        assertEq(usdt.balanceOf(address(vault)), 100_000e6);

        vm.startPrank(users.adam);

        usdt.approve(address(gameFactory), 100e6);
        (, address game0) = gameFactory.createGame(address(0));

        game = Game(game0);

        vm.stopPrank();
    }

    function initializeGame() private {
        vm.startPrank(users.server1);

        IRevealer.InitializeGame memory params = IRevealer.InitializeGame({game: address(game), hashedDeck: deck});

        revealer.initialize(params);

        vm.stopPrank();
    }

    function testFail_guessCardBeforeInitialization() public changeCaller(users.adam) {
        uint256 cards = 0;

        cards += 1 << 5;

        game.guessCard(0, 2e6, cards);
    }

    function test_maximumBetAmount() public {
        assertEq(vault.getMaximumBetAmount(), (usdt.balanceOf(address(vault)) * 2) / 100);
    }

    function test_guessCardForTheFirstTime() public {
        initializeGame();

        vm.startPrank(users.adam);

        uint256 amount = 1e6;
        uint256 guessCards = 0;
        guessCards += 1 << 11;

        usdt.approve(address(game), amount);
        game.guessCard(0, amount, guessCards);

        assertEq(game.cards(0).betAmount, amount);
        assertEq(game.cards(0).requestedAt, block.timestamp);
        assertEq(game.cards(0).revealedNumber, 0);

        vm.stopPrank();

        // vm.startPrank(users.server1);
        //
        // uint256 userBalanceBefore = usdt.balanceOf(users.adam);
        //
        // IRevealer.RevealedCard memory revealParams = IRevealer.RevealedCard({
        //     game: address(game),
        //     isFreeReveal: false,
        //     index: 0,
        //     number: cards[0].number,
        //     salt: cards[0].salt
        // });
        //
        // revealer.revealCard(revealParams);
        //
        // vm.stopPrank();
        //
        // uint256 userBalanceAfter = usdt.balanceOf(users.adam);
        //
        // assert(userBalanceAfter > userBalanceBefore);
    }

    function test_guessCardForSecondTime() public {
        initializeGame();

        vm.startPrank(users.adam);

        uint256 amount = 1e6;
        uint256 guessCards = 0;
        guessCards += 1 << 11;

        usdt.approve(address(game), amount);
        game.guessCard(0, amount, guessCards);

        assertEq(game.cards(0).betAmount, amount);
        assertEq(game.cards(0).requestedAt, block.timestamp);
        assertEq(game.cards(0).revealedNumber, 0);

        amount = 1e6;
        guessCards = 0;
        guessCards += 1 << 11;

        usdt.approve(address(game), amount);
        game.guessCard(1, amount, guessCards);

        assertEq(game.cards(0).betAmount, amount);
        assertEq(game.cards(0).requestedAt, block.timestamp);
        assertEq(game.cards(0).revealedNumber, 0);

        vm.stopPrank();
    }

    function testFail_guessTheSameCardTwice() public {
        initializeGame();

        vm.startPrank(users.adam);

        uint256 amount = 1e6;
        uint256 guessCards = 0;
        guessCards += 1 << 11;

        usdt.approve(address(game), amount * 2);

        game.guessCard(0, amount, guessCards);
        game.guessCard(0, amount, guessCards);

        vm.stopPrank();
    }

    function testFail_guessEveryCard() public {
        initializeGame();

        vm.startPrank(users.adam);

        uint256 amount = 1e6;
        uint256 guessCards = 0;
        guessCards += 1 << 0;
        guessCards += 1 << 1;
        guessCards += 1 << 2;
        guessCards += 1 << 3;
        guessCards += 1 << 4;
        guessCards += 1 << 5;
        guessCards += 1 << 6;
        guessCards += 1 << 7;
        guessCards += 1 << 8;
        guessCards += 1 << 9;
        guessCards += 1 << 10;
        guessCards += 1 << 11;
        guessCards += 1 << 12;

        usdt.approve(address(game), amount);

        game.guessCard(0, amount, guessCards);

        vm.stopPrank();
    }

    function testFail_guessNoCards() public {
        initializeGame();

        vm.startPrank(users.adam);

        uint256 amount = 1e6;
        uint256 guessCards = 0;

        usdt.approve(address(game), amount);

        game.guessCard(0, amount, guessCards);

        vm.stopPrank();
    }

    function testFail_guessCardFromAnotherPlayer() public {
        initializeGame();

        vm.startPrank(users.eve);

        uint256 amount = 1e6;
        uint256 guessCards = 1;

        usdt.approve(address(game), amount);

        game.guessCard(0, amount, guessCards);

        vm.stopPrank();
    }

    function testFail_guessCardWithOverFlowIndex() public {
        initializeGame();

        vm.startPrank(users.eve);

        uint256 index = 100;
        uint256 amount = 1e6;
        uint256 guessCards = 1;

        usdt.approve(address(game), amount);

        game.guessCard(index, amount, guessCards);

        vm.stopPrank();
    }

    function testFail_guessCardWithLessThanMinimumBetAmount() public {
        assertEq(vault.getMinimumBetAmount(), 1e6);

        initializeGame();

        vm.startPrank(users.adam);

        uint256 index = 10;
        uint256 amount = 1e6 - 1;
        uint256 guessCards = 1;

        usdt.approve(address(game), amount);

        game.guessCard(index, amount, guessCards);

        vm.stopPrank();
    }

    function testFail_guessCardWithGreaterThanMaximumBetAmount() public {
        uint256 maxAmount = vault.getMaximumBetAmount();

        initializeGame();

        vm.startPrank(users.adam);

        uint256 index = 10;
        uint256 amount = maxAmount + 1;
        uint256 guessCards = 1;

        usdt.approve(address(game), amount);

        game.guessCard(index, amount, guessCards);

        vm.stopPrank();
    }
}
