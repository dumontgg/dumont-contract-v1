// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";

import {Burner} from "../src/Burner.sol";
import {Constants} from "./utils/Constants.sol";
import {ERC20Custom} from "../script/test/ERC20Custom.sol";
import {GameFactory} from "../src/GameFactory.sol";
import {ISwapRouter02} from "../src/interfaces/Uniswap/ISwapRouter02.sol";
import {MONT} from "../src/MONT.sol";
import {MontRewardManager} from "../src/MontRewardManager.sol";
import {Revealer} from "../src/Revealer.sol";
import {SWAP_ROUTER, SHIBA, USDT, UNISWAP_V3_FACTORY} from "./fork/Addresses.t.sol";
import {USDC} from "./utils/tokens/USDC.t.sol";
import {Users} from "./utils/Types.sol";
import {Vault} from "../src/Vault.sol";

abstract contract BaseTest is Test, Constants {
    Users internal users;

    Burner internal burner;
    ERC20Custom internal usdc;
    GameFactory internal gameFactory;
    MONT internal mont;
    MontRewardManager internal montRewardManager;
    Revealer internal revealer;
    Vault internal vault;

    modifier changeCaller(address caller) {
        vm.startPrank(caller);

        _;

        vm.stopPrank();
    }

    function setUp() public virtual {
        mont = new MONT(100_000_000, address(this));
        usdc = new ERC20Custom(
            "USD Tether",
            "USDC",
            6,
            100_000_000,
            address(this)
        );

        // mont = MONT(address(SHIBA));
        // usdc = ERC20Custom(address(USDT));

        users = Users({
            eve: createUser("Eve"),
            bob: createUser("Bob"),
            adam: createUser("Adam"),
            alice: createUser("Alice"),
            admin: createUser("Admin"),
            server1: createUser("Server1"),
            server2: createUser("Server2")
        });

        vm.label({account: address(mont), newLabel: "MONT"});
        vm.label({account: address(usdc), newLabel: "USDC"});

        deal(address(usdc), users.eve, 100_000_000e6);
        deal(address(mont), users.eve, 100_000_000e18);
        deal(address(mont), users.admin, 100_000_000e18);

        // Warp to May 1, 2023 at 00:00 GMT to provide a more realistic testing environment.
        vm.warp(MAY_1_2023);
    }

    function deployContracts() internal {
        vm.startPrank(users.admin);

        revealer = new Revealer();

        revealer.grantRole(revealer.REVEALER_ROLE(), users.server1);
        revealer.grantRole(revealer.REVEALER_ROLE(), users.server2);

        burner = new Burner();
        burner.initialize(mont, usdc, SWAP_ROUTER, 3000);

        vault = new Vault(
            mont,
            usdc,
            burner,
            GameFactory(address(0x00)),
            MontRewardManager(address(0x00)),
            1e6
        );

        gameFactory = new GameFactory();
        gameFactory.initialize(
            usdc,
            vault,
            address(revealer),
            ONE_HOUR * 12,
            ONE_HOUR * 6,
            5,
            1e6
        );

        montRewardManager = new MontRewardManager(
            address(vault),
            mont,
            usdc,
            gameFactory,
            address(UNISWAP_V3_FACTORY),
            3000,
            1500
        );

        address token0 = address(mont);
        address token1 = address(usdc);

        if (address(mont) > address(usdc)) {
            token0 = address(usdc);
            token1 = address(mont);
        }

        vault.setGameFactory(gameFactory);
        vault.setMontRewardManager(montRewardManager);

        vm.stopPrank();
    }

    /**
     * @notice Creates a new address, gives it a label, transfers ETH and USDC to it
     * @param _name The name used to label the new address
     * @return userAddress Generated address of the user
     */
    function createUser(
        string memory _name
    ) internal returns (address userAddress) {
        userAddress = makeAddr(_name);

        deal(userAddress, 100e18);
        deal(address(usdc), userAddress, 100_000_000e6);
    }
}
