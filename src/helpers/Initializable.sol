// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title Initializable contract
 * @dev Helper contract for managing initialization state
 */
contract Initializable {
    /**
     * @notice Throws if called when the contract is not yet initialized
     */
    error NotInitialized();

    /**
     * @notice Throws if called when the contract already initialized
     */
    error AlreadyInitialized();

    uint256 private constant INITIALIZED = 2;
    uint256 private constant NOT_INITIALIZED = 1;

    uint256 private initialized = NOT_INITIALIZED;

    /**
     * @dev Throws if called when the contract is not yet initialized
     */
    modifier onlyInitialized() {
        if (initialized == NOT_INITIALIZED) {
            revert NotInitialized();
        }

        _;
    }

    /**
     * @dev Throws if called when the contract is already initialized
     */
    modifier onlyNotInitialized() {
        if (initialized == INITIALIZED) {
            revert AlreadyInitialized();
        }

        _;
    }

    /**
     * @dev Marks the contract as initialized
     */
    function initializeContract() internal onlyNotInitialized {
        initialized = INITIALIZED;
    }

    /**
     * @dev Checks if the contract is initialized
     * @return bool true if the contract is initialized, false otherwise
     */
    function isInitialized() public view returns (bool) {
        return initialized == INITIALIZED;
    }
}
