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

    /**
     * @notice Emitted when the UniswapV3 pool fee is changed
     * @param _from The old Uniswap pool fee
     * @param _to The new Uniswap pool fee
     */
    event UniswapPoolFeeChanged(uint24 indexed _from, uint24 indexed _to);

    /**
     * @notice Emitted when the swap router address is changed
     * @param _from The old swap router address
     * @param _to The new swap router address
     */
    event SwapRouterChanged(address indexed _from, address indexed _to);

    function mont() external returns (IMONT);

    function usdt() external returns (IERC20);

    function swapRouter() external returns (ISwapRouter);

    function uniswapPoolFee() external returns (uint24);

    /**
     * @notice Changes the UniswapV3 pool by changing the fee of the pool
     * @param _uniswapPoolFee The new Uniswap pool fee
     * @dev Can only be called by the owner of the contract
     */
    function setUniswapPoolFee(uint24 _uniswapPoolFee) external;

    /**
     * @notice Changes the SwapRouter contract address
     * @param _swapRouter The new SwapRouter contract address
     */
    function setSwapRouter(ISwapRouter _swapRouter) external;

    /**
     * @notice Swaps USDT to MONT and burns MONT tokens
     * @param _amountOutMinimum The minimum amount of MONT to burn
     */
    function burnTokens(uint256 _amountOutMinimum) external;
}
