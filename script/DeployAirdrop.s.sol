// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {console2} from "forge-std/console2.sol";

import {Airdrop} from "../src/Airdrop.sol";
import {MONT} from "../src/MONT.sol";

import {BaseScript} from "./Base.s.sol";

contract DeployAirdrop is BaseScript {
    function run() public virtual broadcast returns (Airdrop airdrop) {
        uint256 amount = 10_000_000e18;
        uint256 claimAmount = 100_000e18;

        MONT montTestnet = MONT(0x163a1b3d68843463C9DC973784EBAC552AF56326);
        MONT montMainnet = MONT(0xaA49D1028d89d56f8f7A8A307d216977847da15e);

        MONT mont = montTestnet;

        if (isBase) {
            mont = montMainnet;
        }

        airdrop = new Airdrop(mont, claimAmount);

        mont.transfer(address(airdrop), amount);

        console2.log("AIRDROP=%s", address(airdrop));
    }
}
