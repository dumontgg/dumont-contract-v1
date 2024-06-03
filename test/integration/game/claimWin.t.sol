// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IntegrationTest} from "../Integration.t.sol";
import {Game} from "../../../src/Game.sol";
import {IRevealer} from "../../../src/interfaces/IRevealer.sol";

contract ClaimWinTest is IntegrationTest {
    event CardClaimed(uint256 indexed _index, uint256 _timestamp);

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

        usdt.approve(address(game), 100e6);

        game.guessCard(index, betAmount, amounts);

        vm.stopPrank();
    }

    function test_claimWinAfterTheTime() public changeCaller(users.adam) {
        assertEq(game.cards(index).guessedAt, block.timestamp);
        assertEq(game.claimableAfter(), ONE_HOUR * 6);

        vm.warp(block.timestamp + (ONE_HOUR * 7));

        assertEq(block.timestamp, MAY_1_2023 + ONE_HOUR * 7);

        game.claimWin(index);
    }

    function testFail_claimWinShouldFailIfCalledBefore() public changeCaller(users.adam) {
        vm.warp(block.timestamp + (ONE_HOUR * 2));

        assertEq(block.timestamp, MAY_1_2023 + ONE_HOUR * 2);

        game.claimWin(index);
    }

    function test_claimWinShouldEmitEvents() public changeCaller(users.adam) {
        vm.warp(block.timestamp + (ONE_HOUR * 7));

        vm.expectEmit(true, true, false, false);

        emit CardClaimed(index, block.timestamp);

        game.claimWin(index);
    }

    function testFail_claimWinShouldNotBeCalledTwice() public changeCaller(users.adam) {
        vm.warp(block.timestamp + (ONE_HOUR * 7));

        game.claimWin(index);
        game.claimWin(index);
    }

    function test_claimWinShouldTransferUSDT() public changeCaller(users.adam) {
        vm.warp(block.timestamp + (ONE_HOUR * 7));

        uint256 userBalanceBefore = usdt.balanceOf(address(users.adam));

        game.claimWin(index);

        uint256 userBalanceAfter = usdt.balanceOf(address(users.adam));

        assertEq(userBalanceAfter, userBalanceBefore + game.cards(index).totalAmount);
    }

    function testFail_claimWinShouldFailIfCalledByUnauthorizedAddress() public {
        vm.warp(block.timestamp + (ONE_HOUR * 7));

        game.claimWin(index);
    }

    function testFail_claimWinShouldFailIfCardIsNotGuessed() public {
        vm.warp(block.timestamp + (ONE_HOUR * 7));

        game.claimWin(index + 1);
    }

    function test_claimWinShouldNotSetMontRewards() public changeCaller(users.adam) {
        vm.warp(block.timestamp + (ONE_HOUR * 7));

        uint256 userBalanceBefore = mont.balanceOf(address(users.adam));

        game.claimWin(index);

        uint256 userBalanceAfter = mont.balanceOf(address(users.adam));

        assertEq(userBalanceAfter, userBalanceBefore);
    }
}
