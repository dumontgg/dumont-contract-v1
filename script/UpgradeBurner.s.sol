// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimeLockController.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {BaseScript} from "./Base.s.sol";
import {Burner} from "../src/Burner.sol";

/// @notice Deploys all core contracts
contract UpgradeBurnerScript is BaseScript {
    ProxyAdmin proxyAdmin = ProxyAdmin(0xaA49D1028d89d56f8f7A8A307d216977847da15e);
    ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(0xaA49D1028d89d56f8f7A8A307d216977847da15e);

    function run() public virtual broadcast returns (Burner burner) {
        burner = new Burner();

        proxyAdmin.upgradeAndCall(proxy, address(burner), emptyByte);
    }
}
