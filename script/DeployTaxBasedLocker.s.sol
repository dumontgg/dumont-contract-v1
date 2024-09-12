// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseScript} from "./Base.s.sol";
import {MONT} from "../src/MONT.sol";
import {TaxBasedLocker} from "../src/TaxBasedLocker.sol";

/// @notice Deploys all core contracts
contract DeployTaxBasedLocker is BaseScript {
    uint256 AMOUNT = 2_000_000_000e18;
    uint256 TEN_YEARS = 60 * 60 * 24 * 365 * 10;
    MONT mont = MONT(0xaA49D1028d89d56f8f7A8A307d216977847da15e);

    function run() public virtual broadcast returns (TaxBasedLocker taxBasedLocker) {
        taxBasedLocker = new TaxBasedLocker(mont, TEN_YEARS);

        mont.approve(address(taxBasedLocker), AMOUNT);

        taxBasedLocker.initialize(AMOUNT);
    }
}
