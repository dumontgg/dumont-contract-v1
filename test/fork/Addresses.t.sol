// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ISwapRouter} from "../../src/interfaces/Uniswap/ISwapRouter.sol";
import {IQuoter} from "../../src/interfaces/Uniswap/IQuoter.sol";

ISwapRouter constant SWAP_ROUTER = ISwapRouter(
    0xE592427A0AEce92De3Edee1F18E0157C05861564
);
IQuoter constant QUOTER = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
