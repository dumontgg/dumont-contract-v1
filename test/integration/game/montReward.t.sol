// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {console2} from "forge-std/console2.sol";
import {IntegrationTest} from "../Integration.t.sol";
import {Game} from "../../../src/Game.sol";
import {IRevealer} from "../../../src/interfaces/IRevealer.sol";

contract MontRewardTest is IntegrationTest {
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

        IRevealer.InitializeGame memory params = IRevealer.InitializeGame({
            game: address(game),
            hashedDeck: deck
        });

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

    function test_revealShouldSetMontRewards()
        public
        changeCaller(users.server1)
    {
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
