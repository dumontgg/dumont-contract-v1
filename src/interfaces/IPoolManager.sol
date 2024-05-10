// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPoolManager {
    event PoolMinted(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    event PoolCollected(uint256 indexed _tokenId);

    event TokenWithdrawn(
        address indexed _token,
        address indexed _recipient,
        uint256 _amount
    );

    function mintPool(
        uint256 _amount0Desired,
        uint256 _amount1Desired,
        uint256 _amount0Min,
        uint256 _amomunt1Min,
        int24 _tickLower,
        int24 _tickUpper
    )
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function burnPool(uint256 _tokenId) external;

    function collectPool(uint256 _tokenId) external;

    function withdraw(
        IERC20 _token,
        address _recipient
    ) external returns (uint256 amount);
}
