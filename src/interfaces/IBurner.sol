// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

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
    event MONTTokensBurned(uint256 _usdtAmount, uint256 _montAmount);

    /**
     * @notice Emitted when the UniswapV3 pool fee is changed
     * @param _from The old Uniswap pool fee
     * @param _to The new Uniswap pool fee
     */
    event UniswapPoolFeeChanged(uint24 _from, uint24 _to);

    /**
     * @notice Emitted when the swap router address is changed
     * @param _from The old swap router address
     * @param _to The new swap router address
     */
    event SwapRouterChanged(address _from, address _to);

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
