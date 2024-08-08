// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IMONT} from "../src/interfaces/IMONT.sol";
import {Initializable} from "./helpers/Initializable.sol";
import {ITaxBasedLocker} from "./interfaces/ITaxBasedLocker.sol";

/**
 * @title TaxBasedLocker Contract
 * @notice Locks tokens for a specified period and applies a burn penalty for early withdrawals.
 * @dev Provides functions for initializing the contract, withdrawing tokens, and calculating the withdrawable amount.
 */
contract TaxBasedLocker is Initializable, Ownable, ITaxBasedLocker {
    using SafeERC20 for IMONT;

    /// @notice Start time of the lockup period
    uint256 public startTime;
    /// @notice Amount that is locked in MONT
    uint256 public lockedAmount;

    /// @notice Address of the MONT token
    IMONT public immutable token;
    /// @notice The duration of the lockup
    uint256 public immutable lockPeriod;

    /**
     * @notice Constructs the TaxBasedLocker contract.
     * @dev Initializes the contract with the ERC20 token address and the lock period.
     * @param _token The address of the ERC20 token to be locked.
     * @param _lockPeriod The period for which the tokens will be locked, in seconds.
     *
     * Requirements:
     *
     * - `_token` must be a valid ERC20 token address.
     * - `_lockPeriod` must be greater than zero.
     */
    constructor(IMONT _token, uint256 _lockPeriod) Ownable(msg.sender) {
        token = _token;
        lockPeriod = _lockPeriod;
    }

    /**
     * @notice Initializes the contract with a specified amount of tokens to lock.
     * @dev Transfers the specified amount of tokens from the caller to the contract.
     * @param _lockedAmount The amount of tokens to lock.
     *
     * Requirements:
     *
     * - The contract must not be already initialized.
     * - The caller must have approved the contract to spend the specified amount of tokens.
     * - The specified amount of tokens must be greater than zero.
     * - The specified amount of tokens must be available in the caller's balance.
     *
     * Emits an {Initialized} event.
     *
     * Throws:
     * - {AlreadyInitialized} if the contract is already initialized.
     * - {NotEnoughTokens} if the caller does not have enough tokens.
     */
    function initialize(uint256 _lockedAmount) external onlyNotInitialized onlyOwner {
        initializeContract();

        if (_lockedAmount == 0) {
            revert InvalidAmount();
        }

        lockedAmount = _lockedAmount;

        uint256 balance = token.balanceOf(address(this));

        if (balance > _lockedAmount) {
            revert InvalidLockedAmount(balance, _lockedAmount);
        }

        if (balance < lockedAmount) {
            token.safeTransferFrom(owner(), address(this), lockedAmount - balance);
        }

        startTime = block.timestamp;

        emit Initialized();
    }

    /**
     * @notice Withdraws the withdrawable amount of tokens.
     * @dev The withdrawable amount is determined by the time elapsed since initialization.
     *      The remaining tokens are burned as a penalty for early withdrawal.
     *
     * Requirements:
     *
     * - The caller must be the owner of the contract.
     *
     * Emits a {Withdrawn} event indicating the amount withdrawn.
     * Emits a {Burnn} event indicating the amount burned.
     */
    function withdraw() external onlyOwner onlyInitialized {
        if (lockedAmount == 0) {
            revert NotEnoughTokens();
        }

        address _owner = owner();

        uint256 withdrawableAmount = calculateWithdrawableAmount();
        uint256 burnableAmount = lockedAmount - withdrawableAmount;

        if (withdrawableAmount > 0) {
            token.safeTransfer(_owner, withdrawableAmount);

            emit Withdrawn(_owner, withdrawableAmount);
        }

        if (burnableAmount > 0) {
            token.burn(burnableAmount);

            emit Burned(_owner, burnableAmount);
        }

        lockedAmount = 0;
    }

    /**
     * @notice Calculates the amount of tokens that can be withdrawn based on the time elapsed since initialization.
     * @dev Returns the amount of tokens that can be withdrawn without penalty.
     *
     * @return The amount of tokens that can be withdrawn.
     */
    function calculateWithdrawableAmount() public view returns (uint256) {
        uint256 elapsedTime = block.timestamp - startTime;

        if (elapsedTime >= lockPeriod) {
            return lockedAmount;
        } else {
            uint256 withdrawableAmount = (lockedAmount * elapsedTime) / lockPeriod;
            return withdrawableAmount;
        }
    }
}
