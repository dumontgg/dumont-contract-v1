// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title Burner contract burns MONT tokens
 * @author X team
 * @notice Burner is used to swap USDT to MONT and burn MONT
 * @dev The contract uses a custom pool in uniswap to burn MONT tokens
 */
interface IBurner {
    /**
     * @notice Emitted when
     * @param _usdtAmount a
     * @param _montAmount a
     */
    event MONTTokensBurned(uint256 _usdtAmount, uint256 _montAmount);

    /**
     * @notice Emitted when
     * @param _from a
     * @param _to a
     */
    event UniswapPoolFeeChanged(uint24 _from, uint24 _to);

    /**
     * @notice Emitted when
     * @param _from a
     * @param _to a
     */
    event SwapRouterChanged(address _from, address _to);

    /**
     * @notice Changes the UniswapV3 pool by changing the fee of the pool
     * @param _uniswapPoolFee The new Uniswap pool fee
     * @dev Can only be called by the owner of the contract
     */
    function setUniswapPoolFee(uint24 _uniswapPoolFee) external;

    /**
     * @notice Swaps USDT to MONT and burns MONT tokens
     * @param _amountOutMinimum The minimum amount of MONT to burn
     */
    function burnTokens(uint256 _amountOutMinimum) external;
}
