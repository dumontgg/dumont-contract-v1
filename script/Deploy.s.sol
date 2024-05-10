// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Burner} from "../src/Burner.sol";
import {GameFactory} from "../src/GameFactory.sol";
import {IMontRewardManager} from "../src/interfaces/IMontRewardManager.sol";
import {Revealer} from "../src/Revealer.sol";
import {Vault} from "../src/Vault.sol";
import {MontRewardManager} from "../src/MontRewardManager.sol";
import {MONT} from "../src/MONT.sol";
import {INonfungiblePositionManager} from "../src/interfaces/Uniswap/INonfungiblePositionManager.sol";

import {BaseScript} from "./Base.s.sol";

/// @notice Deploys all V2 Core contract in the following order:
///
/// 1. {SablierV2Comptroller}
/// 2. {SablierV2LockupDynamic}
/// 3. {SablierV2LockupLinear}
contract DeployCore2 is BaseScript {
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
            MONT mont
        )
    {
        MONT usdt = new MONT(100_000_000e18, msg.sender); // This should have a decimals of 6
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

        // TODO: assign mont to burner
        mont.transfer(address(montRewardManager), 100);

        // create a pair in uniswap
        createPool(address(mont), address(usdt));
    }

    function createPool(address _mont, address _usdt) internal {
        uint24 poolFee = 3000;

        uniswapFactory.createPool(_mont, _usdt, poolFee);

        // todo: use a trustless contract
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: _mont,
            token1: _usdt,
            fee: poolFee,
            tickLower: 0, // todo
            tickUpper: 0, // todo:
            amount0Desired: 0, // todo:
            amount1Desired: 0, // todo
            amount0Min: 0, // todo
            amount1Min: 0, // todo
            recipient: address(this), // todo
            deadline: block.timestamp + 200 // todo
        });

        uniswapNFPM.mint(params);
    }
}
