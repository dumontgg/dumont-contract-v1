// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {console2} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {BaseTest} from "../../Base.t.sol";
import {Vault} from "../../../src/Vault.sol";
import {Burner} from "../../../src/Burner.sol";
import {GameFactory} from "../../../src/GameFactory.sol";
import {RewardManager} from "../../../src/RewardManager.sol";

contract VaultTest is BaseTest {
    uint256 private constant GAME_CREATION_FEE = 1e18;
    uint256 private constant MINIMUM_BET_ = 1e18;

    function setUp() public virtual override {
        BaseTest.setUp();

        vm.prank(users.admin);
        vault = new Vault(
            mont,
            usdt,
            Burner(address(0x00)),
            GameFactory(address(0x00)),
            RewardManager(address(0x00)),
            GAME_CREATION_FEE
        );
    }

    function test_owner() public {
        assertEq(vault.owner(), users.admin);
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
