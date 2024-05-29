// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IntegrationTest} from "../Integration.t.sol";
import {Game} from "../../../src/Game.sol";

contract GameFactoryTest is IntegrationTest {
    function setUp() public virtual override {
        IntegrationTest.setUp();

        deployContracts();

        vm.startPrank(users.adam);

        usdt.approve(address(gameFactory), 100e6);

        vm.stopPrank();
    }

    function test_changedConfigsApplyToNewGames() public changeCaller(users.adam) {
        (, address game0) = gameFactory.createGame(address(0));

        assertEq(Game(game0).maxFreeReveals(), gameFactory.maxFreeReveals());
    }
}
