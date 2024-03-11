// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Test} from "forge-std/Test.sol";

import {Burner} from "../src/Burner.sol";
import {Constants} from "./utils/Constants.sol";
import {GameFactory} from "../src/GameFactory.sol";
import {ISwapRouter} from "../src/interfaces/Uniswap/ISwapRouter.sol";
import {IQuoter} from "../src/interfaces/Uniswap/IQuoter.sol";
import {MONT} from "../src/MONT.sol";
import {RewardManager} from "../src/RewardManager.sol";
import {Revealer} from "../src/Revealer.sol";
import {Users} from "./utils/Types.sol";
import {Vault} from "../src/Vault.sol";

abstract contract BaseTest is Test, Constants {
    Users internal users;

    Burner internal burner;
    GameFactory internal gameFactory;
    MONT internal mont;
    RewardManager internal rewardManager;
    Revealer internal revealer;
    ERC20 internal usdt;
    Vault internal vault;

    function setUp() public virtual {
        mont = new MONT(100_000_000, address(this));
        usdt = new ERC20("Tether USD", "USDT");

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

        deal({token: address(mont), to: users.admin, give: 100_000_000e18});

        // Warp to May 1, 2023 at 00:00 GMT to provide a more realistic testing environment.
        vm.warp(MAY_1_2023);
    }

    function deployContracts() internal {
        revealer = new Revealer();
        vault = new Vault(
            mont,
            usdt,
            Burner(address(0x00)),
            GameFactory(address(0x00)),
            RewardManager(address(0x00)),
            1e18
        );
        gameFactory = new GameFactory(
            usdt,
            vault,
            address(revealer),
            ONE_HOUR * 12,
            1e18
        );
        rewardManager = new RewardManager(
            address(vault),
            mont,
            IQuoter(address(0x00)),
            usdt,
            3000
        );
        burner = new Burner(mont, usdt, ISwapRouter(address(0x00)), 500);

        vault.setBurner(burner);
        vault.setGameFactory(gameFactory);
        vault.setRewardManager(rewardManager);
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

        deal({to: userAddress, give: 100e18});
        deal({token: address(usdt), to: userAddress, give: 100_000_000e18});
    }
}
