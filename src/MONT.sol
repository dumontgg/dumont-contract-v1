// SPDX-License-Identifier: MI
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IMONT} from "./interfaces/IMONT.sol";

/**
 * @title MONT Token Contract
 * @dev Implementation of the Dumont ERC20 token with burn functionality
 * @notice This token is used to reward winners of the game
 */
contract MONT is ERC20, IMONT {
    /**
     * @notice Constructor function to create the token with the specified amount
     * @param _amount Total supply of the token
     * @param _recipient The recipient address that receives all the supply
     */
    constructor(uint256 _amount, address _recipient) ERC20("Dumont Token", "MONT") {
        _mint(_recipient, _amount * 10 ** decimals());
    }

    /**
     * @notice Burns an amount of tokens of the caller
     * @param _amount Amount to burn from the caller's balance
     * @dev This function can be called by anyone to burn tokens from their own balance
     */
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}
