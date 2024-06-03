// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";

import {IQuoter} from "../src/interfaces/Uniswap/IQuoter.sol";
import {ISwapRouter} from "../src/interfaces/Uniswap/ISwapRouter.sol";
import {IUniswapV3Factory} from "../src/interfaces/Uniswap/IUniswapV3Factory.sol";
import {INonfungiblePositionManager} from "../src/interfaces/Uniswap//INonfungiblePositionManager.sol";

abstract contract BaseScript is Script {
    /// @dev Included to enable compilation of the script without a $MNEMONIC environment variable.
    string internal constant TEST_MNEMONIC =
        "test test test test test test test test test test test junk";

    /// @dev Needed for the deterministic deployments.
    bytes32 internal constant ZERO_SALT = bytes32(0);

    /// @dev The address of the transaction broadcaster.
    address internal broadcaster;

    /// @dev The address of the revealers
    address internal revealer1;
    address internal revealer2;
    address internal revealer3;

    /// @dev Used to derive the broadcaster's address if $ETH_FROM is not defined.
    string internal mnemonic;

    address internal UNISWAP_QUOTER_MAINNET =
        0x61fFE014bA17989E743c5F6cB21bF9697530B21e;
    address internal UNISWAP_QUOTER_SEPOLIA =
        0xEd1f6473345F45b75F8179591dd5bA1888cf2FB3;

    address internal UNISWAP_SWAP_ROUTER_MAINNET =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address internal UNISWAP_SWAP_ROUTER_SEPOLIA =
        0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;

    // TODO: fix addrss
    address internal UNISWAP_FACTORY_MAINNET =
        0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;
    address internal UNISWAP_FACTORY_SEPOLIA =
        0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;

    // TODO: fix addrss
    address internal UNISWAP_NFPM_MAINNET =
        0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;
    address internal UNISWAP_NFPM_SEPOLIA =
        0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;

    // TODO: take env value and see the network selected and assign the right address to quoter and swaprouter
    IQuoter uniswapQuoter = IQuoter(UNISWAP_QUOTER_SEPOLIA);
    ISwapRouter uniswapSwapRouter = ISwapRouter(UNISWAP_SWAP_ROUTER_SEPOLIA);
    IUniswapV3Factory uniswapFactory =
        IUniswapV3Factory(UNISWAP_FACTORY_SEPOLIA);
    INonfungiblePositionManager uniswapNFPM =
        INonfungiblePositionManager(UNISWAP_NFPM_SEPOLIA);

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
}