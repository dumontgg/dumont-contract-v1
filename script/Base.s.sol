// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {MONT} from "../src/MONT.sol";
import {ERC20Custom} from "./test/ERC20Custom.sol";
import {ISwapRouter02} from "../src/interfaces/Uniswap/ISwapRouter02.sol";
import {INonfungiblePositionManager} from "./test/INonfungiblePositionManager.sol";

abstract contract BaseScript is Script {
    bytes internal emptyByte;
    address[] emptyAddressArray;
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;
    bytes32 internal constant ZERO_SALT = bytes32(0);

    address internal constant BASE_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address internal constant UNISWAP_SWAP_ROUTER_BASE = 0x2626664c2603336E57B271c5C0b26F421741e481;
    address internal constant UNISWAP_SWAP_ROUTER_SEPOLIA = 0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4;
    address internal constant UNISWAP_V3_FACTORY_BASE = 0x33128a8fC17869897dcE68Ed026d694621f6FDfD;
    address internal constant UNISWAP_V3_FACTORY_SEPOLIA = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address internal constant UNISWAP_NFPM_BASE = 0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1;
    address internal constant UNISWAP_NFPM_SEPOLIA = 0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;

    /// @dev The address of the transaction broadcaster.
    address internal broadcaster;

    /// @dev Determines the deployment on base or base sepolia
    bool internal isBase;

    /// @dev The address of the revealers
    address[] internal revealers;

    /// @dev Uniswap addresses based on the network
    INonfungiblePositionManager internal uniswapNFPM;
    address internal uniswapV3Factory;
    ISwapRouter02 internal uniswapSwapRouter;

    /// @dev Initializes the transaction broadcaster like this:
    ///
    /// - Sets the $ETH_FROM, $REVEALERS, and $IS_BASE
    constructor() {
        isBase = vm.envOr("IS_BASE", false);
        broadcaster = vm.envOr("ETH_FROM", address(0));
        revealers = vm.envOr("REVEALERS", ",", emptyAddressArray);

        if (isBase) {
            uniswapNFPM = INonfungiblePositionManager(UNISWAP_NFPM_BASE);
            uniswapV3Factory = UNISWAP_V3_FACTORY_BASE;
            uniswapSwapRouter = ISwapRouter02(UNISWAP_SWAP_ROUTER_BASE);
        } else {
            uniswapNFPM = INonfungiblePositionManager(UNISWAP_NFPM_SEPOLIA);
            uniswapV3Factory = UNISWAP_V3_FACTORY_SEPOLIA;
            uniswapSwapRouter = ISwapRouter02(UNISWAP_SWAP_ROUTER_SEPOLIA);
        }
    }

    modifier broadcast() {
        vm.startBroadcast(broadcaster);

        _;

        vm.stopBroadcast();
    }

    function createPool(address _token0, address _token1, uint24 _fee, uint160 _sqrtPriceX96)
        internal
        returns (address pool)
    {
        pool = uniswapNFPM.createAndInitializePoolIfNecessary(_token0, _token1, _fee, _sqrtPriceX96);
    }

    function mintPool(address _token0, address _token1, uint24 _fee, uint256 _amount0, uint256 _amount1) internal {
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: _token0,
            token1: _token1,
            fee: _fee,
            tickLower: MIN_TICK - (MIN_TICK % 60),
            tickUpper: MAX_TICK - (MAX_TICK % 60),
            amount0Desired: _amount0,
            amount1Desired: _amount1,
            amount0Min: 0,
            amount1Min: 0,
            recipient: msg.sender,
            deadline: type(uint256).max
        });

        IERC20(_token0).approve(address(uniswapNFPM), type(uint256).max);
        IERC20(_token1).approve(address(uniswapNFPM), type(uint256).max);

        uniswapNFPM.mint(params);
    }
}
