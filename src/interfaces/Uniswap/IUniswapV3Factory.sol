// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IUniswapV3Factory {
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);
}
