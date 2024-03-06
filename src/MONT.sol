// SPDX-License-Identifier: MI
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IMONT} from "./interfaces/IMONT.sol";

/**
 * @title Dumont ERC20 token implementation
 * @dev The ERC20 function has a burn functionality and its totalSupply will only decrease
 * @notice This token is used to reward winners of the game
 */
contract MONT is ERC20, IMONT {
    /**
     * @notice Creates the token with the specified amount and sends all supply to the _recipient
     * @param _amount Total supply of the token
     * @param _recipient The recipient that receives all the supply
     */
    constructor(uint256 _amount, address _recipient) ERC20("Dumont Token", "MONT") {
        _mint(_recipient, _amount * 10 ** decimals());
    }

    /**
     * @notice Burns an amount of tokens of msg.sender
     * @param _amount Amount to burn from msg.sender
     * @dev This function can be called by anyone to burn tokens
     */
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}
