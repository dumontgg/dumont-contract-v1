// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {DMN} from "../src/DMN.sol";
import {BaseTest} from "./Base.t.sol";
import {Vault} from "../src/Vault.sol";
import {Burner} from "../src/Burner.sol";
import {GameFactory} from "../src/GameFactory.sol";
import {IVault} from "../src/interfaces/IVault.sol";
import {ISwapRouter} from "../src/interfaces/ISwapRouter.sol";

contract VaultTest is BaseTest {
    function setUp() public virtual override {
        BaseTest.setUp();
    }
    // function setUp() public {
    //     DMN dmn = new DMN(200000000, address(this));
    //     ERC20 dai = new ERC20("DAI", "DAI");
    //     Burner burner = new Burner(dmn, dai, ISwapRouter(address(this)), 3000);
    //     GameFactory gameFactory = new GameFactory(IVault(address(this)), address(this));
    //
    //     uint256 gameFeeInWei = 3000000;
    //
    //     vault = new Vault(dmn, dai, burner, gameFactory, gameFeeInWei);
    // }

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
