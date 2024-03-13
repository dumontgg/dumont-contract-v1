// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console2} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {UD60x18, ud} from "@prb/math/src/UD60x18.sol";

import {BaseTest} from "../../Base.t.sol";
import {Vault} from "../../../src/Vault.sol";
import {Burner} from "../../../src/Burner.sol";
import {Game} from "../../../src/Game.sol";
import {GameFactory} from "../../../src/GameFactory.sol";
import {RewardManager} from "../../../src/RewardManager.sol";

contract GameTest is BaseTest {
    Game public game;

    function setUp() public virtual override {
        BaseTest.setUp();

        changePrank({msgSender: users.admin});

        deployContracts();

        game = new Game(usdt, vault, users.server1, users.alice, 0, 200);
    }

    function test_owner() public {
        assertEq(vault.owner(), users.admin);
    }

    function test_rate() public {
        uint256[] memory cards = new uint256[](12);

        cards[0] = uint256(1);
        cards[0] = 2;
        cards[0] = 4;
        cards[0] = 4;
        cards[0] = 4;
        cards[0] = 4;
        cards[0] = 4;
        cards[0] = 4;
        cards[0] = 4;
        cards[0] = 4;
        cards[0] = 4;
        cards[0] = 4;

        UD60x18 a = game.getRate2(cards);
        uint256 b = a.mul(ud(1e18)).unwrap();

        console2.log("%s", b);
    }

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
