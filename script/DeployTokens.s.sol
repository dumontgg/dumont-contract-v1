// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ERC20Custom} from "./test/ERC20Custom.sol";
import {INonfungiblePositionManager} from "./test/INonfungiblePositionManager.sol";
import {MONT} from "../src/MONT.sol";

import {BaseScript} from "./Base.s.sol";

contract DeployTokensScript is BaseScript {
    function run()
        public
        virtual
        broadcast
        returns (ERC20Custom usdt, MONT mont, address pool)
    {
        usdt = new ERC20Custom(
            "USD Tether",
            "USDT",
            6,
            100_000_000,
            msg.sender
        );
        mont = new MONT(100_000_000_000, msg.sender);

        if (address(usdt) > address(mont)) {
            uint256 amount0 = 2_000_000_000e18;
            uint256 amount1 = 500_000e6;
            uint160 sqrt = 560_227_709_747_861_389_312;

            pool = createPool(
                address(mont),
                address(usdt),
                3000,
                sqrt,
                amount0,
                amount1
            );
        } else {
            uint256 amount0 = 500_000e6;
            uint256 amount1 = 2_000_000_000e18;
            uint160 sqrt = 11_204_554_194_957_228_823_252_587_668_406_534_144;

            pool = createPool(
                address(usdt),
                address(mont),
                3000,
                sqrt,
                amount0,
                amount1
            );
        }
    }
}
