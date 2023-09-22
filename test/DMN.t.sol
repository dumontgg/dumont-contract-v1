// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {DMN} from "../src/DMN.sol";

contract DMNTest is Test {
    DMN public token;

    function setUp() public {
        token = new DMN(uint256(200), address(this));
    }

    function test_decimals() public {
        assertEq(token.decimals(), 18);
    }

    function test_totalSupply() public {
        assertEq(token.totalSupply(), 200000000000000000000);
    }

    function test_burn() public {
        token.burn(100 * 10 ** 18);

        assertEq(token.totalSupply(), 100 * 10 ** 18);
    }

    function test_balanceOf() public {
        assertEq(token.balanceOf(address(this)), 200 * 10 ** 18);
    }
}
