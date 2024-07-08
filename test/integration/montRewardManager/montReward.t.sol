// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IntegrationTest} from "../Integration.t.sol";
import {Game} from "../../../src/Game.sol";
import {IRevealer} from "../../../src/interfaces/IRevealer.sol";

contract MontRewardTest is IntegrationTest {
    event MontRewardAssigned(address indexed _player, uint256 _reward);

    error Unauthorized();

    Game public game;

    uint256 index0 = 0;
    uint256 numbers0 = 32; // index 0 is the wrong choice, because the card is an 11
    uint256 amount0 = 2e6;

    uint256 index1 = 1;
    uint256 numbers1 = 512; // index 1 is the right choice
    uint256 amount1 = 1e6;

    uint256 index2 = 2; // request free reveal

    function setUp() public virtual override {
        IntegrationTest.setUp();

        assertEq(usdt.balanceOf(address(vault)), 100_000e6);

        vm.startPrank(users.adam);

        usdt.approve(address(gameFactory), 100e6);
        (, address game0) = gameFactory.createGame(address(0));

        game = Game(game0);

        usdt.approve(address(game), type(uint256).max);

        vm.stopPrank();

        vm.startPrank(users.server1);

        IRevealer.InitializeGame memory params = IRevealer.InitializeGame({game: address(game), hashedDeck: deck});

        revealer.initialize(params);

        vm.stopPrank();

        assert(game.isInitialized());
        assertEq(game.player(), users.adam);

        vm.startPrank(users.adam);

        game.guessCard(index0, amount0, numbers0);
        game.guessCard(index1, amount1, numbers1);
        game.requestFreeRevealCard(index2);

        vm.stopPrank();
    }

    function test_revealShouldSetMontRewards() public changeCaller(users.server1) {
        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: index0,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        uint256 usdtBalanceBefore = usdt.balanceOf(users.adam);
        uint256 montBalanceBefore = montRewardManager.balances(users.adam);

        revealer.revealCard(params);

        uint256 usdtBalanceAfter = usdt.balanceOf(users.adam);
        uint256 montBalanceAfter = montRewardManager.balances(users.adam);

        assert(usdtBalanceBefore == usdtBalanceAfter); // since the player lost
        assert(montBalanceBefore < montBalanceAfter); // losers get mont anyways

        vm.stopPrank();

        vm.startPrank(users.adam);

        uint256 montBalanceBeforeClaim = mont.balanceOf(users.adam);

        montRewardManager.claim();

        uint256 montBalanceAfterClaim = mont.balanceOf(users.adam);

        assert(montBalanceAfterClaim > montBalanceBeforeClaim);

        vm.stopPrank();
    }

    function test_revealShouldSetMontToReferrer() public {
        vm.startPrank(users.adam);

        (, address game0Address) = gameFactory.createGame(users.eve);

        vm.stopPrank();
        vm.startPrank(users.server1);

        IRevealer.InitializeGame memory params = IRevealer.InitializeGame({game: game0Address, hashedDeck: deck});
        IRevealer.RevealedCard memory revealParams = IRevealer.RevealedCard({
            game: game0Address,
            index: index0,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        revealer.initialize(params);

        vm.stopPrank();

        vm.startPrank(users.adam);

        usdt.approve(game0Address, type(uint256).max);
        Game(game0Address).guessCard(index0, amount0, numbers0);

        vm.stopPrank();

        vm.startPrank(users.server1);

        uint256 referrerBalanceBefore = montRewardManager.balances(users.eve);

        revealer.revealCard(revealParams);

        uint256 referrerBalanceAfter = montRewardManager.balances(users.eve);

        assert(referrerBalanceAfter > referrerBalanceBefore);

        vm.stopPrank();

        vm.startPrank(users.eve);

        uint256 refferrerClaimed = montRewardManager.claim();

        assert(refferrerClaimed > 0);

        vm.stopPrank();
    }

    function test_revealShouldSetMoreMontIfReferrerIsSet() public {
        vm.startPrank(users.adam);

        (, address game0Address) = gameFactory.createGame(address(0));

        vm.stopPrank();
        vm.startPrank(users.server1);

        IRevealer.InitializeGame memory params = IRevealer.InitializeGame({game: game0Address, hashedDeck: deck});
        IRevealer.RevealedCard memory revealParams = IRevealer.RevealedCard({
            game: game0Address,
            index: index0,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        revealer.initialize(params);

        vm.stopPrank();

        vm.startPrank(users.adam);

        usdt.approve(game0Address, type(uint256).max);
        Game(game0Address).guessCard(index0, amount0, numbers0);

        vm.stopPrank();

        vm.startPrank(users.server1);

        revealer.revealCard(revealParams);

        vm.stopPrank();

        vm.startPrank(users.adam);

        uint256 amuontWithoutReferrer = montRewardManager.claim();

        (, address game1Address) = gameFactory.createGame(users.eve);

        vm.stopPrank();
        vm.startPrank(users.server1);

        params.game = game1Address;
        revealParams.game = game1Address;

        revealer.initialize(params);

        vm.stopPrank();

        vm.startPrank(users.adam);

        usdt.approve(game1Address, type(uint256).max);
        Game(game1Address).guessCard(index0, amount0, numbers0);

        vm.stopPrank();

        vm.startPrank(users.server1);

        revealer.revealCard(revealParams);

        vm.stopPrank();

        vm.startPrank(users.adam);

        uint256 amountWithReferrer = montRewardManager.claim();

        vm.stopPrank();

        assert(amountWithReferrer > amuontWithoutReferrer);
    }

    function test_claimMontRewards() public changeCaller(users.server1) {
        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: index0,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        uint256 claimableAmountBefore = montRewardManager.balances(users.adam);

        assert(claimableAmountBefore == 0);

        revealer.revealCard(params);

        uint256 claimableAmountAfter = montRewardManager.balances(users.adam);

        assert(claimableAmountAfter > 0);
        assert(claimableAmountAfter > claimableAmountBefore);

        vm.stopPrank();
        vm.startPrank(users.adam);

        uint256 montBalanceBefore = mont.balanceOf(users.adam);

        montRewardManager.claim();

        uint256 montBalanceAfter = mont.balanceOf(users.adam);

        assert(montBalanceAfter > montBalanceBefore);

        assertEq(montRewardManager.balances(users.adam), 0);

        vm.stopPrank();
    }

    function test_callingClaimTwiceShouldNotGiveMoreMontTokens() public changeCaller(users.server1) {
        IRevealer.RevealedCard memory params = IRevealer.RevealedCard({
            game: address(game),
            index: index0,
            salt: cards[0].salt,
            isFreeReveal: false,
            number: cards[0].number
        });

        uint256 claimableAmountBefore = montRewardManager.balances(users.adam);

        assert(claimableAmountBefore == 0);

        revealer.revealCard(params);

        uint256 claimableAmountAfter = montRewardManager.balances(users.adam);

        assert(claimableAmountAfter > 0);
        assert(claimableAmountAfter > claimableAmountBefore);

        vm.stopPrank();
        vm.startPrank(users.adam);

        uint256 montBalanceBefore = mont.balanceOf(users.adam);

        montRewardManager.claim();

        uint256 montBalanceAfter = mont.balanceOf(users.adam);

        assert(montBalanceAfter > montBalanceBefore);

        assertEq(montRewardManager.balances(users.adam), 0);

        montRewardManager.claim();

        uint256 montBalanceAfterSecondClaim = mont.balanceOf(users.adam);

        assertEq(montBalanceAfter, montBalanceAfterSecondClaim);

        vm.stopPrank();
    }

    function test_claimMontsUnauthorizedShouldRevert() public changeCaller(users.eve) {
        vm.expectRevert(Unauthorized.selector);
        montRewardManager.transferPlayerRewards(1e6, 1e18, 1e5, users.eve, true);
    }

    function test_setMontShouldEmitEvents() public changeCaller(users.server1) {
        IRevealer.RevealedCard memory revealParams = IRevealer.RevealedCard({
            game: address(game),
            index: index1,
            salt: cards[1].salt,
            isFreeReveal: false,
            number: cards[1].number
        });

        vm.expectEmit(true, false, false, false);
        emit MontRewardAssigned(users.adam, 20000);

        revealer.revealCard(revealParams);
    }
}
