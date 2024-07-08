// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

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
            ERC20Custom usdt
        )
    {
        usdt = new ERC20Custom("USD Tether", "USDT", 6, 100_000_000, msg.sender);
        mont = new MONT(100_000_000e18, msg.sender);
        burner = new Burner(mont, usdt, uniswapSwapRouter, 3000);
        revealer = new Revealer();
        vault = new Vault(
            mont,
            usdt,
            burner,
            GameFactory(address(0)),
            IMontRewardManager(address(0)), // MontRewardManager
            1e6
        );
        gameFactory = new GameFactory(usdt, vault, address(revealer), 1 days / 2, 1 days / 6, 3, 1e6);
        montRewardManager = new MontRewardManager(address(vault), mont, usdt, gameFactory, uniswapQuoter, 3000);

        vault.setMontRewardManager(montRewardManager);
        vault.setGameFactory(gameFactory);

        revealer.grantRole(revealer.REVEALER_ROLE(), revealer1);
        revealer.grantRole(revealer.REVEALER_ROLE(), revealer2);
        revealer.grantRole(revealer.REVEALER_ROLE(), revealer3);

        usdt.transfer(address(vault), 100_000e6);
        mont.transfer(address(montRewardManager), 1_000_000e18);
    }
}
