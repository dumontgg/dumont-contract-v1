// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IMONT} from "./IMONT.sol";
import {ISwapRouter02} from "./Uniswap/ISwapRouter02.sol";

/**
 * @title Burner contract burns MONT tokens
 * @notice Burner is used to swap USDC to MONT and burn MONT
 */
interface IBurner {
    /**
     * @notice Emitted when MONT tokens are burned
     * @param _usdcAmount The amount of USDC swapped
     * @param _montAmount The amount of MONT burned
     */
    event MONTTokensBurned(uint256 indexed _usdcAmount, uint256 indexed _montAmount);

    /**
     * @notice Throws when there are not enough USDC tokens to burn
     */
    error NotEnoughUSDC();

    /**
     * @notice Throws when deadline is passed for swap using Uniswap SwapRouter
     */
    error DeadlinePassed();

    /**
     * @notice Returns the MONT token address
     */
    function mont() external returns (IMONT);

    /**
     * @notice Returns the USDC token address
     */
    function usdc() external returns (IERC20);

    /**
     * @notice Returns the Uniswap SwapRouter contract address
     */
    function swapRouter() external returns (ISwapRouter02);

    /**
     * @notice Returns the Uniswap USDC-MONT pool fee tier
     */
    function uniswapPoolFee() external returns (uint24);

    /**
     * @notice Swaps USDC to MONT and burns MONT tokens
     * @param _amountOutMinimum The minimum amount of MONT to burn
     * @param _deadline Deadline of the swap
     */
    function burnTokens(uint256 _amountOutMinimum, uint256 _deadline) external;
}
