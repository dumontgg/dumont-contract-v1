// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IntegrationTest} from "../Integration.t.sol";
import {Game} from "../../../src/Game.sol";
import {IRevealer} from "../../../src/interfaces/IRevealer.sol";

contract RevealCardTest is IntegrationTest {
    enum CardStatus {
        SECRETED,
        GUESSED,
        CLAIMED,
        FREE_REVEAL_REQUESTED,
        REVEALED
    }

    event CardRevealed(uint256 indexed _gameId, uint256 indexed _index, uint256 indexed _number, bytes32 _salt);

    error NotAuthorized(uint256 _gameId, address _caller);
    error CardIsNotSecret(uint256 _gameId, uint256 _index);
    error CardIsAlreadyClaimable(uint256 _gameId, uint256 _index);
    error CardStatusIsNotFreeRevealRequested(uint256 _gameId, uint256 _index);
    error InvalidSalt(uint256 _gameId, uint256 _index, uint256 _number, bytes32 _salt);

    Game public game;
    uint256 public gameId;

    uint256 index0 = 0;
    uint256 numbers0 = 1; // index 0 is the wrong choice, because the card is an 11
    uint256 amount0 = 1e6;

    uint256 index1 = 1;
    uint256 numbers1 = 512; // index 1 is the right choice
    uint256 amount1 = 1e6;

    function setUp() public virtual override {
        IntegrationTest.setUp();

        assertEq(usdc.balanceOf(address(vault)), 100_000e6);

        vm.startPrank(users.adam);

        usdc.approve(address(gameFactory), 100e6);
        (uint256 _gameId, address game0Address) = gameFactory.createGame(address(0));

        setCards(game0Address);

        game = Game(game0Address);
        gameId = _gameId;

        usdc.approve(address(game), 100e6);

        vm.stopPrank();

        vm.startPrank(users.server1);

        IRevealer.InitializeGame memory params = IRevealer.InitializeGame({game: address(game), hashedDeck: deck});

        revealer.initialize(params);

        vm.stopPrank();

        vm.startPrank(users.adam);

        game.guessCard(index0, amount0, numbers0);
        game.guessCard(index1, amount1, numbers1);
        game.requestFreeRevealCard(2);

        vm.stopPrank();

        assertEq(game.cardsFreeRevealedRequests(), 1);
    }

    function test_revealCard() public changeCaller(users.server1) {
        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: index0,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        revealer.revealCard(params);

        assertEq(uint256(game.cards(index0).status), uint256(CardStatus.REVEALED));
        assertEq(game.cards(index0).revealedNumber, cards[0].number);
        assertEq(game.cards(index0).hash, cards[0].hash);
        assertEq(game.cards(index0).revealedSalt, cards[0].salt);
    }

    function test_revealCardWithTheRightData() public changeCaller(users.server1) {
        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: index0,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        revealer.revealCard(params);

        assertEq(uint256(game.cards(index0).status), uint256(CardStatus.REVEALED));
        assertEq(game.cards(index0).revealedNumber, cards[0].number);
        assertEq(game.cards(index0).hash, cards[0].hash);
        assertEq(game.cards(index0).revealedSalt, cards[0].salt);
    }

    function test_revealCardAfterClaimableAfterDurationShouldRevert() public changeCaller(users.server1) {
        vm.warp(block.timestamp + (ONE_HOUR * 7));

        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: index0,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        vm.expectRevert(abi.encodeWithSelector(CardIsAlreadyClaimable.selector, gameId, index0));
        revealer.revealCard(params);
    }

    function test_revertIfRevealCardIsCalledWithWrongData() public changeCaller(users.server1) {
        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: index0,
            salt: cards[1].salt,
            isFreeReveal: false,
            number: cards[1].number
        });

        vm.expectRevert(abi.encodeWithSelector(InvalidSalt.selector, gameId, index0, cards[1].number, cards[1].salt));

        revealer.revealCard(params);
    }

    function test_revertIfRevealCardIsCalledDirectly() public changeCaller(users.server1) {
        vm.expectRevert(abi.encodeWithSelector(NotAuthorized.selector, gameId, users.server1));

        game.revealCard(index0, cards[0].number, cards[0].salt, false);
    }

    function test_revealMultipleCards() public changeCaller(users.server1) {
        IRevealer.RevealedCard[] memory params = new IRevealer.RevealedCard[](2);

        params[0] = IRevealer.RevealedCard({
            game: address(game),
            index: index0,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        params[1] = IRevealer.RevealedCard({
            game: address(game),
            index: index1,
            salt: cards[1].salt,
            isFreeReveal: false,
            number: cards[1].number
        });

        revealer.revealCardBatch(params);
    }

    function testFail_revertUnauthorizedRevealCard() public changeCaller(users.bob) {
        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: index0,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        revealer.revealCard(params);
    }

    function test_revealGuessCardAsFreeRevealShouldRevert() public changeCaller(users.server1) {
        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: index0,
            salt: cards[0].salt,
            isFreeReveal: true,
            number: cards[0].number
        });

        vm.expectRevert(abi.encodeWithSelector(CardStatusIsNotFreeRevealRequested.selector, gameId, index0));

        revealer.revealCard(params);
    }

    function test_revealFreeRevealCardAsGuessCardShouldRevert() public changeCaller(users.server1) {
        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: 2,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        uint256 index2 = 2;

        vm.expectRevert(abi.encodeWithSelector(CardIsNotSecret.selector, gameId, index2));

        revealer.revealCard(params);
    }

    function test_revealCardShouldChangeCardsRevealedVariable() public changeCaller(users.server1) {
        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: 0,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        revealer.revealCard(params);

        assertEq(game.cardsRevealed(), 1);

        IRevealer.RevealedCard memory params1 = IRevealer.RevealedCard({
            game: address(game),
            index: 1,
            salt: cards[1].salt,
            isFreeReveal: false,
            number: cards[1].number
        });

        revealer.revealCard(params1);

        assertEq(game.cardsRevealed(), 2);
    }

    function test_revealCardShouldNotChangeFreeRevealedVariable() public changeCaller(users.server1) {
        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: 0,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        revealer.revealCard(params);

        assertEq(game.revealedCardNumbersCount(11), 1);
        assertEq(game.revealedCardNumbersCount(1), 0);

        IRevealer.RevealedCard memory params1 = IRevealer.RevealedCard({
            game: address(game),
            index: 1,
            salt: cards[1].salt,
            isFreeReveal: false,
            number: cards[1].number
        });

        revealer.revealCard(params1);

        assertEq(game.revealedCardNumbersCount(11), 1);
        assertEq(game.revealedCardNumbersCount(9), 1);
    }

    function test_revealCardShouldTransferUSDCIfWon() public changeCaller(users.server1) {
        uint256 balanceBefore = usdc.balanceOf(game.player());

        uint256 amount = game.cards(0).totalAmount;

        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: 1,
            salt: cards[1].salt,
            isFreeReveal: false,
            number: cards[1].number
        });

        revealer.revealCard(params);

        uint256 balanceAfter = usdc.balanceOf(game.player());

        assertEq(balanceAfter, balanceBefore + amount);
    }

    function test_revealCardShouldNotTransferUSDCIfLost() public changeCaller(users.server1) {
        uint256 balanceBefore = usdc.balanceOf(game.player());

        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: 0,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        revealer.revealCard(params);

        uint256 balanceAfter = usdc.balanceOf(game.player());

        assertEq(balanceAfter, balanceBefore);
    }

    function test_revealTheSameCardTwiceShouldRevert() public changeCaller(users.server1) {
        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: index0,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        revealer.revealCard(params);

        vm.expectRevert(abi.encodeWithSelector(CardIsNotSecret.selector, gameId, index0));

        revealer.revealCard(params);
    }

    function test_revealCardShouldEmitEvents() public changeCaller(users.server1) {
        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: index0,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        vm.expectEmit(true, true, true, false);

        emit CardRevealed(gameId, index0, cards[0].number, cards[0].salt);

        revealer.revealCard(params);
    }

    function test_initializeBatch() public {
        vm.startPrank(users.adam);
        (, address game0Address) = gameFactory.createGame(address(0));
        (, address game1Address) = gameFactory.createGame(address(0));
        vm.stopPrank();

        vm.startPrank(users.server1);

        IRevealer.InitializeGame[] memory params = new IRevealer.InitializeGame[](2);

        IRevealer.InitializeGame memory game0Params = IRevealer.InitializeGame({game: game0Address, hashedDeck: deck});

        IRevealer.InitializeGame memory game1Params = IRevealer.InitializeGame({game: game1Address, hashedDeck: deck});

        params[0] = game0Params;
        params[1] = game1Params;

        revealer.initializeBatch(params);

        vm.stopPrank();
    }
}
