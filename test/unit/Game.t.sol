// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {UD60x18, ud} from "@prb/math/src/UD60x18.sol";

import {BaseTest} from "../Base.t.sol";
import {Burner} from "../../src/Burner.sol";
import {Game} from "../../src/Game.sol";
import {GameFactory} from "../../src/GameFactory.sol";
import {IRevealer} from "../../src/interfaces/IRevealer.sol";
import {MontRewardManager} from "../../src/MontRewardManager.sol";
import {Vault} from "../../src/Vault.sol";

contract GameTest is BaseTest {
    Game public game;
    uint256 public id;
    address public gameAddress;

    function setUp() public virtual override {
        BaseTest.setUp();

        deployContracts();

        vm.startPrank(users.adam);

        usdt.approve(address(gameFactory), gameFactory.gameCreationFee());

        (uint256 id_, address gameAddress_) = gameFactory.createGame(address(0));

        id = id_;
        game = Game(gameAddress_);
        gameAddress = gameAddress_;

        vm.stopPrank();
    }

    function test_vault() public {
        assertEq(address(game.vault()), address(vault));
    }

    function test_baseConfigs() public {
        assertEq(game.gameDuration(), gameFactory.gameDuration());
        assertEq(game.maxFreeReveals(), gameFactory.maxFreeReveals());
        assertEq(game.claimableAfter(), gameFactory.claimableAfter());
    }

    function test_initializeGame() public {
        vm.startPrank(users.server1);

        bytes32[52] memory deck;

        IRevealer.InitializeGame memory params = IRevealer.InitializeGame({game: address(game), hashedDeck: deck});

        revealer.initialize(params);

        vm.stopPrank();
    }
}
