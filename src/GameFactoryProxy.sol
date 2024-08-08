// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract GameFactoryProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _admin, bytes memory _data)
        TransparentUpgradeableProxy(_logic, _admin, _data)
    {}
}
