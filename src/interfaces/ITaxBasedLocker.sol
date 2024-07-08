// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title TaxBasedLocker Interface
 * @notice Interface for the TaxBasedLocker contract that locks tokens for a specified period and applies a burn penalty for early withdrawals.
 * @dev Provides functions for initializing the contract, withdrawing tokens, and calculating the withdrawable amount.
 */
interface ITaxBasedLocker {
    /**
     * @dev Emitted when the contract is initialized.
     */
    event Initialized();

    /**
     * @dev Emitted when tokens are withdrawn by the owner.
     * @param owner The address of the owner withdrawing the tokens.
     * @param withdrawableAmount The amount of tokens withdrawn.
     */
    event Withdrawn(address indexed owner, uint256 withdrawableAmount);

    /**
     * @dev Emitted when tokens are burned due to early withdrawal.
     * @param owner The address of the owner whose tokens are burned.
     * @param burnableAmount The amount of tokens burned.
     */
    event Burned(address indexed owner, uint256 burnableAmount);

    /**
     * @dev Thrown when the contract has already been initialized.
     */
    error AlreadyInitialized();

    /**
     * @dev Thrown when there are not enough tokens to initialize the contract.
     */
    error NotEnoughTokens();

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
    function initialize(uint256 _lockedAmount) external;

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
    function withdraw() external;

    /**
     * @notice Calculates the amount of tokens that can be withdrawn based on the time elapsed since initialization.
     * @dev Returns the amount of tokens that can be withdrawn without penalty.
     *
     * @return The amount of tokens that can be withdrawn.
     */
    function calculateWithdrawableAmount() external view returns (uint256);
}
