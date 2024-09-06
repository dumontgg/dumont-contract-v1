// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import {IMONT} from "./interfaces/IMONT.sol";
import {IBurner} from "./interfaces/IBurner.sol";
import {ISwapRouter02} from "./interfaces/Uniswap/ISwapRouter02.sol";

/**
 * @title Burner contract burns MONT tokens
 * @notice Burner is used to swap USDC to MONT and burn MONT
 * @dev The contract uses a custom pool in Uniswap to burn MONT tokens
 */
contract Burner is IBurner, Ownable2StepUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice Address of the MONT token
    IMONT public mont;
    /// @notice Address of the USDC token
    IERC20 public usdc;
    /// @notice Fee of the Uniswap V3 pool for MONT-USDC
    uint24 public uniswapPoolFee;
    /// @notice Address of the Uniswap SwapRouter contract
    ISwapRouter02 public swapRouter;

    /**
     * @notice Sets related contract addresses
     * @param _mont The address of the MONT ERC20 token contract
     * @param _usdc The address of the USDC token
     * @param _swapRouter The address of the UniswapV3 SwapRouter contract
     * @param _uniswapPoolFee The fee of the UniswapV3 pool
     */
    function initialize(IMONT _mont, IERC20 _usdc, ISwapRouter02 _swapRouter, uint24 _uniswapPoolFee)
        external
        initializer
    {
        mont = _mont;
        usdc = _usdc;
        swapRouter = _swapRouter;
        uniswapPoolFee = _uniswapPoolFee;

        usdc.forceApprove(address(_swapRouter), type(uint256).max);

        __Ownable2Step_init();
        __Ownable_init(msg.sender);
    }

    /**
     * @notice Swaps USDC to MONT and burns MONT tokens
     * @param _amountOutMinimum The minimum amount of MONT to burn
     * @param _deadline Deadline of the swap
     * @dev Emits MONTTokensBurned event
     */
    function burnTokens(uint256 _amountOutMinimum, uint256 _deadline) external onlyOwner {
        uint256 usdcBalance = usdc.balanceOf(address(this));

        if (usdcBalance == 0) {
            revert NotEnoughUSDC();
        }

        // Swap is used to convert all USDC tokens to MONT tokens
        _swap(usdcBalance, _amountOutMinimum, _deadline);

        uint256 montBalance = mont.balanceOf(address(this));

        mont.burn(montBalance);

        emit MONTTokensBurned(usdcBalance, montBalance);
    }

    /**
     * @notice Swaps USDC to get MONT using a UniswapV3 pool
     * @param _amountIn The amount of USDC to swap
     * @param _amountOutMinimum The minimum amount of MONT to receive
     */
    function _swap(uint256 _amountIn, uint256 _amountOutMinimum, uint256 _deadline)
        private
        returns (uint256 amountOut)
    {
        if (block.timestamp > _deadline) {
            revert DeadlinePassed();
        }

        ISwapRouter02.ExactInputSingleParams memory params = ISwapRouter02.ExactInputSingleParams({
            fee: uniswapPoolFee,
            amountIn: _amountIn,
            tokenIn: address(usdc),
            tokenOut: address(mont),
            recipient: address(this),
            sqrtPriceLimitX96: 0,
            amountOutMinimum: _amountOutMinimum
        });

        amountOut = swapRouter.exactInputSingle(params);
    }
}
