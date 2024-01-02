// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Dumont ERC20 token implementation
 * @dev The ERC20 function has a burn functionality and its totalSupply will only decrease
 * @notice This token is used to reward winners of the game
 */
interface IDMT is IERC20 {
    /**
     * @notice Burns an amount of tokens
     * @param _amount Amount to burn from msg.sender
     * @dev This function can be called by anyone to burn tokens
     */
    function burn(uint256 _amount) external;
}
