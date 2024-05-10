// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IMONT} from "./IMONT.sol";
import {ISwapRouter} from "./Uniswap/ISwapRouter.sol";

/**
 * @title Burner contract burns MONT tokens
 * @notice Burner is used to swap USDT to MONT and burn MONT
 */
interface IBurner {
    /**
     * @notice Emitted when MONT tokens are burned
     * @param _usdtAmount The amount of USDT swapped
     * @param _montAmount The amount of MONT burned
     */
    event MONTTokensBurned(uint256 indexed _usdtAmount, uint256 indexed _montAmount);

    // TODO:
    function mont() external returns (IMONT);

    // TODO:
    function usdt() external returns (IERC20);

    // TODO:
    function swapRouter() external returns (ISwapRouter);

    // TODO:
    function uniswapPoolFee() external returns (uint24);

    /**
     * @notice Swaps USDT to MONT and burns MONT tokens
     * @param _amountOutMinimum The minimum amount of MONT to burn
     */
    function burnTokens(uint256 _amountOutMinimum) external;
}
