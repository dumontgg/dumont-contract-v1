// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MONT Token Contract
 * @dev Implementation of the Dumont ERC20 token with burn functionality
 * @notice This token is used to reward winners of the game
 */
interface IMONT is IERC20 {
    /**
     * @notice Burns an amount of tokens of the caller
     * @param _amount Amount to burn from the caller's balance
     * @dev This function can be called by anyone to burn tokens from their own balance
     */
    function burn(uint256 _amount) external;
}
