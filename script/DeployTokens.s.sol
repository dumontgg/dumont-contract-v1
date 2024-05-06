// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {MONT} from "../src/MONT.sol";
import {ERC20Custom} from "./test/ERC20Custom.sol";

import {BaseScript} from "./Base.s.sol";

contract DeployTokensScript is BaseScript {
    function run() public virtual broadcast returns (ERC20Custom usdt, MONT mont) {
        usdt = new ERC20Custom("USD Tether", "USDT", 6, 100_000_000, msg.sender);
        mont = new MONT(100_000_000_000, msg.sender);
    }
}
