// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimeLockController.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {BaseScript} from "./Base.s.sol";
import {GameFactory} from "../src/GameFactory.sol";

/// @notice Deploys all core contracts
contract UpgradeGameFactoryScript is BaseScript {
    ProxyAdmin proxyAdmin = ProxyAdmin(0xEB976152c2440EB95B8b3210474a69807E72De49);
    ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(0xB1d07348b340D1184680A9560baa7D4604Cd91F9);

    function run() public virtual broadcast returns (GameFactory gameFactory) {
        gameFactory = new GameFactory();

        proxyAdmin.upgradeAndCall(proxy, address(gameFactory), emptyByte);
    }
}
