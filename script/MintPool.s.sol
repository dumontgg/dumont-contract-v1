// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ERC20Custom} from "./test/ERC20Custom.sol";
import {INonfungiblePositionManager} from "./test/INonfungiblePositionManager.sol";
import {MONT} from "../src/MONT.sol";

import {BaseScript} from "./Base.s.sol";

contract MintPool is BaseScript {
    function run() public virtual broadcast returns (ERC20Custom usdcToken, MONT montToken, address pool) {
        usdcToken = ERC20Custom(BASE_USDC);
        montToken = MONT(0xaA49D1028d89d56f8f7A8A307d216977847da15e);
        pool = 0x798675121F0B4B5f0B64acacb3C844a6341e4472;

        if (address(usdcToken) > address(montToken)) {
            uint256 amount0 = 100_000e18;
            uint256 amount1 = 1e6;

            mintPool(address(montToken), address(usdcToken), 3000, amount0, amount1);
        } else {
            uint256 amount0 = 1e6;
            uint256 amount1 = 100_000e18;

            mintPool(address(usdcToken), address(montToken), 3000, amount0, amount1);
        }
    }
}
