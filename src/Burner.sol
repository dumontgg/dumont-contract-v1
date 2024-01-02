// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IDMT} from "./interfaces/IDMT.sol";
import {IBurner} from "./interfaces/IBurner.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";

/**
 * @title Burner contract burns DMN tokens
 * @author X team
 * @notice Burner is used to swap DAI to DMN and burn DMN
 * @dev The contract uses a custom pool in uniswap to burn DMN tokens
 */
contract Burner is IBurner, Ownable2Step {
    using SafeERC20 for IERC20;

    IDMT public dmt;
    IERC20 public usdt;
    ISwapRouter public swapRouter;

    uint24 public uniswapPoolFee;

    event DMTTokensBurned(uint256 _usdtAmount, uint256 _dmnAmount);
    event UniswapPoolFeeChanged(uint24 _from, uint24 _to);

    /**
     * @notice Sets related contract addresses
     * @param _dmt The address of the DMN ERC20 token contract
     * @param _usdt The address of the USDT token
     * @param _swapRouter The address of the UniswapV3 SwapRouter contract
     * @param _uniswapPoolFee The fee of the UniswapV3 pool
     */
    constructor(IDMT _dmt, IERC20 _usdt, ISwapRouter _swapRouter, uint24 _uniswapPoolFee) {
        usdt = _usdt;
        dmt = _dmt;
        swapRouter = _swapRouter;

        uniswapPoolFee = _uniswapPoolFee;

        usdt.forceApprove(address(_swapRouter), type(uint256).max);
    }

    /**
     * @notice Swaps DAI to get DMN using a UniswapV3 pool
     * @param _amountIn The amount of DAI to swap
     * @param _amountOutMinimum The minimum amount of DMN to receive
     */
    function _swap(uint256 _amountIn, uint256 _amountOutMinimum) private returns (uint256 amountOut) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            fee: uniswapPoolFee,
            amountIn: _amountIn,
            tokenIn: address(usdt),
            tokenOut: address(dmt),
            recipient: address(this),
            deadline: block.timestamp,
            amountOutMinimum: _amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        amountOut = swapRouter.exactInputSingle(params);
    }

    /**
     * @notice Changes the UniswapV3 pool by changing the fee of the pool
     * @param _uniswapPoolFee The new Uniswap pool fee
     * @dev Can only be called by the owner of the contract
     */
    function setUniswapPoolFee(uint24 _uniswapPoolFee) external onlyOwner {
        emit UniswapPoolFeeChanged(uniswapPoolFee, _uniswapPoolFee);

        uniswapPoolFee = _uniswapPoolFee;
    }

    /**
     * @notice Swaps DAI to DMN and burns DMN tokens
     * @param _amountOutMinimum The minimum amount of DMN to burn
     */
    function burnTokens(uint256 _amountOutMinimum) external onlyOwner {
        uint256 daiBalance = usdt.balanceOf(address(this));

        // Swap is used to convert all DAI tokens to DMN tokens
        _swap(daiBalance, _amountOutMinimum);

        uint256 dmnBalance = dmt.balanceOf(address(this));

        emit DMTTokensBurned(daiBalance, dmnBalance);

        dmt.burn(dmnBalance);
    }
}
