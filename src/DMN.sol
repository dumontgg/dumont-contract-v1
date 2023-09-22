// SPDX-License-Identifier: MI
pragma solidity 0.8.20;

import {IDMN} from "./interfaces/IDMN.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Dumont ERC20 token implementation
 * @author X team
 * @dev The ERC20 function has a burn functionality and its totalSupply will only decrease
 * @notice This token is used to reward winners of the game
 */
contract DMN is ERC20, IDMN {
    /**
     * @notice Creates the token with the specified amount and sends all supply to the _recipient
     * @param _amount Total supply of the token
     * @param _recipient The recipient that receives all the supply
     */
    constructor(uint256 _amount, address _recipient) ERC20("Dumont Token", "DMN") {
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
