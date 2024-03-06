// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import {IMONT} from "./interfaces/IMONT.sol";
import {IRewardManager} from "./interfaces/IRewardManager.sol";

contract RewardManager is Ownable2Step, IRewardManager {
    IMONT public mont;
    address public vault;

    constructor(address _vault, IMONT _mont) {
        mont = _mont;
        vault = _vault;
    }

    modifier onlyVault() {
        if (msg.sender != vault) {
            revert Unauthorized();
        }

        _;
    }

    /**
     * @notice Changes the Vault address
     * @param _vault new Vault contract
     */
    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    function transferRewards(address player, uint256 _betAmount) external onlyVault {}
}
