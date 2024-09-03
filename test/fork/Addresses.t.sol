// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IMONT} from "../../src/interfaces/IMONT.sol";
import {IUniswapV3Factory} from "./interfaces/IUniswapV3Factory.sol";
import {ISwapRouter02} from "../../src/interfaces/Uniswap/ISwapRouter02.sol";
import {INonfungiblePositionManager} from "./interfaces/INonfungiblePositionManager.sol";

IMONT constant SHIBA = IMONT(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE);
IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
ISwapRouter02 constant SWAP_ROUTER = ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
IUniswapV3Factory constant UNISWAP_V3_FACTORY = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
INonfungiblePositionManager constant NFPM = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
