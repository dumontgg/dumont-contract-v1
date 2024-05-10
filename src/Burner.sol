// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IMONT} from "./interfaces/IMONT.sol";
import {IBurner} from "./interfaces/IBurner.sol";
import {ISwapRouter} from "./interfaces/Uniswap/ISwapRouter.sol";

/**
 * @title Burner contract burns MONT tokens
 * @notice Burner is used to swap USDT to MONT and burn MONT
 * @dev The contract uses a custom pool in uniswap to burn MONT tokens
 */
contract Burner is IBurner, Ownable2Step {
    using SafeERC20 for IERC20;

    IMONT public immutable mont;
    IERC20 public immutable usdt;
    uint24 public immutable uniswapPoolFee;
    ISwapRouter public immutable swapRouter;

    /**
     * @notice Sets related contract addresses
     * @param _mont The address of the MONT ERC20 token contract
     * @param _usdt The address of the USDT token
     * @param _swapRouter The address of the UniswapV3 SwapRouter contract
     * @param _uniswapPoolFee The fee of the UniswapV3 pool
     */
    constructor(IMONT _mont, IERC20 _usdt, ISwapRouter _swapRouter, uint24 _uniswapPoolFee) Ownable(msg.sender) {
        mont = _mont;
        usdt = _usdt;
        swapRouter = _swapRouter;
        uniswapPoolFee = _uniswapPoolFee;

        usdt.forceApprove(address(_swapRouter), type(uint256).max);
    }

    /**
     * @notice Swaps USDT to MONT and burns MONT tokens
     * @param _amountOutMinimum The minimum amount of MONT to burn
     */
    function burnTokens(uint256 _amountOutMinimum) external onlyOwner {
        uint256 usdtBalance = usdt.balanceOf(address(this));

        if (usdtBalance == 0) {
            revert NotEnoughUSDT();
        }

        // Swap is used to convert all USDT tokens to MONT tokens
        _swap(usdtBalance, _amountOutMinimum);

        uint256 montBalance = mont.balanceOf(address(this));

        mont.burn(montBalance);

        emit MONTTokensBurned(usdtBalance, montBalance);
    }

    /**
     * @notice Swaps USDT to get MONT using a UniswapV3 pool
     * @param _amountIn The amount of USDT to swap
     * @param _amountOutMinimum The minimum amount of MONT to receive
     */
    function _swap(uint256 _amountIn, uint256 _amountOutMinimum) private returns (uint256 amountOut) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            fee: uniswapPoolFee,
            amountIn: _amountIn,
            tokenIn: address(usdt),
            tokenOut: address(mont),
            recipient: address(this),
            deadline: block.timestamp,
            amountOutMinimum: _amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        amountOut = swapRouter.exactInputSingle(params);
    }
}
