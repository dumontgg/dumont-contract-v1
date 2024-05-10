// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {console2} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {UD60x18, ud} from "@prb/math/src/UD60x18.sol";

import {BaseTest} from "../../Base.t.sol";
import {Vault} from "../../../src/Vault.sol";
import {Burner} from "../../../src/Burner.sol";
import {Game} from "../../../src/Game.sol";
import {GameFactory} from "../../../src/GameFactory.sol";
import {MontRewardManager} from "../../../src/MontRewardManager.sol";

contract GameTest is BaseTest {
    Game public game;

    function setUp() public virtual override {
        BaseTest.setUp();

        // deployContracts();
        //
        // game = new Game(usdt, vault, users.server1, users.alice, 0, ONE_HOUR * 12, ONE_HOUR * 6, 3);
    }

    // function test_owner() public {
    //     assertEq(vault.owner(), users.admin);
    // }
    //
    // function test_rate() public view {
    //     bool[13] memory cards = [true, false, false, true, false, true, false, true, false, true, false, true, false];
    //
    //     UD60x18 a = game.getGuessRate(cards);
    //     uint256 b = a.mul(ud(1e18)).unwrap();
    //
    //     console2.log("%s", b);
    // }

    // function testFuzz_depositWithdrawDAI(uint256 amount) public {
    //     vault.depositDai(amount);
    //
    //     uint256 preBalance = dai.balanceOf(address(this));
    //
    //     vault.withdrawToken(address(dai), amount, address(this));
    //
    //     uint256 postBalance = dai.balanceOf(address(this));
    //
    //     assertEq(preBalance + amount, postBalance);
    // }
}
