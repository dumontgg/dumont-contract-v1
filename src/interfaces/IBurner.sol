// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title Burner contract burns DMN tokens
 * @author X team
 * @notice Burner is used to swap DAI to DMN and burn DMN
 * @dev The contract uses a custom pool in uniswap to burn DMN tokens
 */
interface IBurner {
    /**
     * @notice Changes the UniswapV3 pool by changing the fee of the pool
     * @param _uniswapPoolFee The new Uniswap pool fee
     * @dev Can only be called by the owner of the contract
     */
    function setUniswapPoolFee(uint24 _uniswapPoolFee) external;

    /**
     * @notice Swaps DAI to DMN and burns DMN tokens
     * @param _amountOutMinimum The minimum amount of DMN to burn
     */
    function burnTokens(uint256 _amountOutMinimum) external;
}
