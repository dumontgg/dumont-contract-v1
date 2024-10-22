// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IAirdrop} from "./interfaces/IAirdrop.sol";
import {MONT} from "./MONT.sol";

/**
 * @title Airdrop contract
 * @notice Sets the eligible addresses and handles claim
 */
contract Airdrop is Ownable, IAirdrop {
    using SafeERC20 for MONT;

    /// MONT token address
    MONT public immutable mont;

    /// CLaim amount that is given to each claimer to be claimed
    uint256 public claimAmount;
    /// Total amount of MONT that is claimed
    uint256 public totalMontClaimed;
    /// Claimers with the amount that they can claim
    mapping(address => uint256) public claimers;

    /**
     * @notice Constructor to set initial values
     * @param _mont Address of the Dumont token contract
     * @param _claimAmount Initial amount of claim amount to give to each claimer
     */
    constructor(MONT _mont, uint256 _claimAmount) Ownable(msg.sender) {
        mont = _mont;
        claimAmount = _claimAmount;
    }

    /**
     * @notice Adds a claimer
     * @param _claimer Address of the claimer
     */
    function addClaimer(address _claimer) external onlyOwner {
        _addClaimer(_claimer);
    }

    /**
     * @notice Adds multiple claimers
     * @param _claimers Address of the claimers
     */
    function addClaimers(address[] calldata _claimers) external onlyOwner {
        uint256 len = _claimers.length;

        for (uint256 i = 0; i < len; ++i) {
            _addClaimer(_claimers[i]);
        }
    }

    /**
     * @notice Changes the claim amount from now on
     * @param _claimAmount New claim amount in MONT
     */
    function setClaimAmount(uint256 _claimAmount) external onlyOwner {
        emit ClaimAmountChanged(claimAmount, _claimAmount);

        claimAmount = _claimAmount;
    }

    /**
     * @notice Claims the MONT if the caller is eligible
     */
    function claim() external {
        uint256 claimableAmount = claimers[msg.sender];

        if (claimableAmount == 0) {
            revert NotEligible(msg.sender);
        }

        claimers[msg.sender] = 0;

        mont.safeTransfer(msg.sender, claimableAmount);

        totalMontClaimed += claimableAmount;

        emit Claimed(msg.sender, claimableAmount);
    }

    /**
     * @notice Withdraws any remaining MONT that is not claimed by the claimers
     */
    function withdraw() external onlyOwner {
        uint256 amount = mont.balanceOf(address(this));

        mont.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Adds a claimer and emits a ClaimerAdded event
     * @param _claimer Address of the new claimer
     */
    function _addClaimer(address _claimer) private {
        claimers[_claimer] = claimAmount;

        emit ClaimerAdded(_claimer);
    }
}
