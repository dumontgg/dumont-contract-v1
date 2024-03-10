// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {BaseTest} from "../../Base.t.sol";
import {Vault} from "../../../src/Vault.sol";

contract VaultTest is BaseTest {
    function setUp() public virtual override {
        BaseTest.setUp();
    }

    function test_owner() public {
        assertEq(vault.owner(), address(this));
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
