// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {TimelockController} from "@openzeppelin/contracts/governance/TimeLockController.sol";

import {Burner} from "../src/Burner.sol";
import {GameFactory} from "../src/GameFactory.sol";
import {IMontRewardManager} from "../src/interfaces/IMontRewardManager.sol";
import {Revealer} from "../src/Revealer.sol";
import {Vault} from "../src/Vault.sol";
import {ERC20Custom} from "./test/ERC20Custom.sol";
import {MontRewardManager} from "../src/MontRewardManager.sol";
import {MONT} from "../src/MONT.sol";

import {BaseScript} from "./Base.s.sol";

/// @notice Deploys all core contracts
contract DeployCore is BaseScript {
    address[] public EMPTY_ADDRESS_ARRAY;

    uint256 MIN_DELAY = 1 days / 6;
    uint256 GAME_DURATION = 1 days / 2;
    uint256 CLAIMABLE_AFTER = 1 days / 6;
    uint256 MAX_FREE_REVEALS = 3;
    uint24 MONT_USDT_POOL_FEE = 3000;
    uint256 GAME_CREATION_FEE = 1e6;
    uint256 MINIMUM_BET_AMOUNT = 1e6;
    uint256 MONT_INITIAL_SUPPLY = 10_000_000_000;
    uint256 VAULT_INITIAL_USDT_SUPPLY = 100_000e6;
    uint256 MONT_REWARD_MANAGER_INITIAL_MONT_SUPPLY = 1_000_000e18;

    // ADDRESS UNISWAP_QUOTER

    function run()
        public
        virtual
        broadcast
        returns (
            Burner burner,
            GameFactory gameFactory,
            Revealer revealer,
            Vault vault,
            MontRewardManager montRewardManager,
            MONT mont,
            ERC20Custom usdt,
            TimelockController timeLockController
        )
    {
        // todo: use env to check if we should create the USDT token or use its address
        usdt = new ERC20Custom("USD Tether", "USDT", 6, 100_000_000, msg.sender);
        mont = new MONT(MONT_INITIAL_SUPPLY, msg.sender);
        burner = new Burner(mont, usdt, uniswapSwapRouter, MONT_USDT_POOL_FEE);
        revealer = new Revealer();
        vault =
            new Vault(mont, usdt, burner, GameFactory(address(0)), IMontRewardManager(address(0)), MINIMUM_BET_AMOUNT);
        gameFactory = new GameFactory(
            usdt, vault, address(revealer), GAME_DURATION, CLAIMABLE_AFTER, MAX_FREE_REVEALS, GAME_CREATION_FEE
        );
        montRewardManager =
            new MontRewardManager(address(vault), mont, usdt, gameFactory, uniswapQuoter, MONT_USDT_POOL_FEE);
        timeLockController = new TimelockController(MIN_DELAY, EMPTY_ADDRESS_ARRAY, EMPTY_ADDRESS_ARRAY, address(this));

        vault.setMontRewardManager(montRewardManager);
        vault.setGameFactory(gameFactory);

        revealer.grantRole(revealer.REVEALER_ROLE(), revealer1);
        revealer.grantRole(revealer.REVEALER_ROLE(), revealer2);
        revealer.grantRole(revealer.REVEALER_ROLE(), revealer3);

        usdt.transfer(address(vault), VAULT_INITIAL_USDT_SUPPLY);
        mont.transfer(address(montRewardManager), MONT_REWARD_MANAGER_INITIAL_MONT_SUPPLY);

        vault.transferOwnership(address(timeLockController));
        gameFactory.transferOwnership(address(timeLockController));
    }
}
