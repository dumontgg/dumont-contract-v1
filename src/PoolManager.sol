// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {INonfungiblePositionManager} from "./interfaces/Uniswap/INonfungiblePositionManager.sol";
import {IPoolManager} from "./interfaces/IPoolManager.sol";

contract PoolManager is Ownable, IPoolManager {
    using SafeERC20 for IERC20;

    INonfungiblePositionManager public nfpm;
    address public token0;
    address public token1;
    uint24 public fee;

    constructor(INonfungiblePositionManager _nfpm, address _token0, address _token1, uint24 _fee) Ownable(msg.sender) {
        fee = _fee;
        nfpm = _nfpm;
        token0 = _token0;
        token1 = _token1;
    }

    function mintPool(
        uint256 _amount0Desired,
        uint256 _amount1Desired,
        uint256 _amount0Min,
        uint256 _amomunt1Min,
        int24 _tickLower,
        int24 _tickUpper
    ) external onlyOwner returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: fee,
            tickLower: _tickLower,
            tickUpper: _tickUpper,
            amount0Desired: _amount0Desired,
            amount1Desired: _amount1Desired,
            amount0Min: _amount0Min,
            amount1Min: _amomunt1Min,
            recipient: address(this),
            deadline: block.timestamp + 30
        });

        (tokenId, liquidity, amount0, amount1) = nfpm.mint(params);

        emit PoolMinted(tokenId, liquidity, amount0, amount1);
    }

    function burnPool(uint256 _tokenId) external onlyOwner {
        (,,,,,,, uint128 liquidity,,,,) = nfpm.positions(_tokenId);

        INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager
            .DecreaseLiquidityParams({
            tokenId: _tokenId,
            liquidity: liquidity,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp + 30
        });

        nfpm.decreaseLiquidity(params);

        nfpm.burn(_tokenId);
    }

    function collectPool(uint256 _tokenId) external onlyOwner {
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: _tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });

        nfpm.collect(params);

        emit PoolCollected(_tokenId);
    }

    function withdraw(IERC20 _token, address _recipient) external onlyOwner returns (uint256 amount) {
        amount = _token.balanceOf(address(this));

        _token.safeTransfer(_recipient, amount);

        emit TokenWithdrawn(address(_token), _recipient, amount);
    }
}
