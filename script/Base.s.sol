// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {MONT} from "../src/MONT.sol";
import {ERC20Custom} from "./test/ERC20Custom.sol";
import {ISwapRouter} from "../src/interfaces/Uniswap/ISwapRouter.sol";
import {INonfungiblePositionManager} from "./test/INonfungiblePositionManager.sol";

abstract contract BaseScript is Script {
    /// @dev Included to enable compilation of the script without a $MNEMONIC environment variable.
    string internal constant TEST_MNEMONIC =
        "test test test test test test test test test test test junk";

    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev Needed for the deterministic deployments.
    bytes32 internal constant ZERO_SALT = bytes32(0);

    /// @dev The address of the transaction broadcaster.
    address internal broadcaster;

    /// @dev The address of the revealers
    address internal revealer1 = 0x1E7A7Bb102c04e601dE48a68A88Ec6EE59C372b9;
    address internal revealer2 = 0x40fA98c764c1602E5Fb9D201f580B19978B2d4a0;
    address internal revealer3 = 0x3e03984BF3b9Cfa9fC640eCe3ee7a55Fef14Fe15;

    /// @dev Used to derive the broadcaster's address if $ETH_FROM is not defined.
    string internal mnemonic;

    address internal UNISWAP_SWAP_ROUTER_BASE =
        0x2626664c2603336E57B271c5C0b26F421741e481; // todo
    address internal UNISWAP_SWAP_ROUTER_MAINNET =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address internal UNISWAP_SWAP_ROUTER_SEPOLIA =
        0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4;

    address internal UNISWAP_V3_FACTORY_BASE =
        0x33128a8fC17869897dcE68Ed026d694621f6FDfD; // todo
    address internal UNISWAP_V3_FACTORY_MAINNET =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address internal UNISWAP_V3_FACTORY_SEPOLIA =
        0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;

    address internal UNISWAP_NFPM_BASE =
        0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1; // todo
    address internal UNISWAP_NFPM_MAINNET =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address internal UNISWAP_NFPM_SEPOLIA =
        0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;

    // todo: use env
    ISwapRouter uniswapSwapRouter = ISwapRouter(UNISWAP_SWAP_ROUTER_SEPOLIA); // todo
    address uniswapV3Factory = UNISWAP_V3_FACTORY_SEPOLIA; // todo
    address uniswapNFPM = UNISWAP_NFPM_SEPOLIA; // todo

    /// @dev Initializes the transaction broadcaster like this:
    ///
    /// - If $ETH_FROM is defined, use it.
    /// - Otherwise, derive the broadcaster address from $MNEMONIC.
    /// - If $MNEMONIC is not defined, default to a test mnemonic.
    ///
    /// The use case for $ETH_FROM is to specify the broadcaster key and its address via the command line.
    constructor() {
        address from = vm.envOr({name: "ETH_FROM", defaultValue: address(0)});

        if (from != address(0)) {
            broadcaster = from;
        } else {
            mnemonic = vm.envOr({
                name: "MNEMONIC",
                defaultValue: TEST_MNEMONIC
            });

            (broadcaster, ) = deriveRememberKey({mnemonic: mnemonic, index: 0});
            (revealer1, ) = deriveRememberKey({mnemonic: mnemonic, index: 1});
            (revealer2, ) = deriveRememberKey({mnemonic: mnemonic, index: 2});
            (revealer3, ) = deriveRememberKey({mnemonic: mnemonic, index: 3});
        }
    }

    modifier broadcast() {
        vm.startBroadcast(broadcaster);

        _;

        vm.stopBroadcast();
    }

    function createPool(
        address _token0,
        address _token1,
        uint24 _fee,
        uint160 _sqrtPriceX96,
        uint256 _amount0,
        uint256 _amount1
    ) internal returns (address pool) {
        INonfungiblePositionManager nfpm = INonfungiblePositionManager(
            uniswapNFPM
        );

        pool = nfpm.createAndInitializePoolIfNecessary(
            _token0,
            _token1,
            _fee,
            _sqrtPriceX96
        );

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
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

        IERC20(_token0).approve(address(nfpm), type(uint256).max);
        IERC20(_token1).approve(address(nfpm), type(uint256).max);

        nfpm.mint(params);
    }
}
