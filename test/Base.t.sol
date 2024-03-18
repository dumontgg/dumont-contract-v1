// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Test} from "forge-std/Test.sol";

import {Burner} from "../src/Burner.sol";
import {Constants} from "./utils/Constants.sol";
import {GameFactory} from "../src/GameFactory.sol";
import {ISwapRouter} from "../src/interfaces/Uniswap/ISwapRouter.sol";
import {IQuoter} from "../src/interfaces/Uniswap/IQuoter.sol";
import {MONT} from "../src/MONT.sol";
import {MontRewardManager} from "../src/MontRewardManager.sol";
import {Revealer} from "../src/Revealer.sol";
import {USDT} from "./utils/tokens/USDT.t.sol";
import {Users} from "./utils/Types.sol";
import {Vault} from "../src/Vault.sol";
import {SWAP_ROUTER} from "./fork/Addresses.t.sol";

abstract contract BaseTest is Test, Constants {
    Users internal users;

    Burner internal burner;
    GameFactory internal gameFactory;
    MONT internal mont;
    MontRewardManager internal montRewardManager;
    Revealer internal revealer;
    ERC20 internal usdt;
    Vault internal vault;

    function setUp() public virtual {
        mont = new MONT(100_000_000, address(this));
        usdt = new USDT();

        vm.label({account: address(mont), newLabel: "MONT"});
        vm.label({account: address(usdt), newLabel: "USDT"});

        users = Users({
            eve: createUser("Eve"),
            bob: createUser("Bob"),
            adam: createUser("Adam"),
            alice: createUser("Alice"),
            admin: createUser("Admin"),
            server1: createUser("Server1"),
            server2: createUser("Server2")
        });

        deal(address(mont), users.admin, 100_000_000e18);

        // Warp to May 1, 2023 at 00:00 GMT to provide a more realistic testing environment.
        vm.warp(MAY_1_2023);
    }

    function deployContracts() internal {
        vm.startPrank(users.admin);

        revealer = new Revealer();
        vault = new Vault(
            mont,
            usdt,
            Burner(address(0x00)),
            GameFactory(address(0x00)),
            MontRewardManager(address(0x00)),
            1e18
        );
        gameFactory = new GameFactory(
            usdt,
            vault,
            address(revealer),
            ONE_HOUR * 12,
            ONE_HOUR * 6,
            1e18,
            3
        );
        montRewardManager = new MontRewardManager(
            address(vault),
            mont,
            usdt,
            gameFactory,
            IQuoter(address(0x00)),
            3000
        );
        burner = new Burner(mont, usdt, SWAP_ROUTER, 500);

        vault.setBurner(burner);
        vault.setGameFactory(gameFactory);
        vault.setMontRewardManager(montRewardManager);

        vm.stopPrank();
    }

    /**
     * @notice Creates a new address, gives it a label, transfers ETH and USDT to it
     * @param _name The name used to label the new address
     * @return userAddress Generated address of the user
     */
    function createUser(
        string memory _name
    ) internal returns (address userAddress) {
        userAddress = makeAddr(_name);

        deal(userAddress, 100e18);
        deal(address(usdt), userAddress, 100_000_000e18);
    }
}
