// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {console2} from "forge-std/console2.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimeLockController.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

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

    uint256 MIN_DELAY = 0; // khodam
    uint256 GAME_DURATION = 1 days / 2;
    uint256 CLAIMABLE_AFTER = 1 days / 4;
    uint256 MAX_FREE_REVEALS = 3;
    uint32 TWAP_INTERVAL = 1000;
    uint24 MONT_USDC_POOL_FEE = 3000; // 30000? 3%
    uint256 GAME_CREATION_FEE = 1e6;
    uint256 MINIMUM_BET_AMOUNT = 1e6;
    uint256 MONT_INITIAL_SUPPLY = 10_000_000_000;
    uint256 VAULT_INITIAL_USDC_SUPPLY = 100_000e6;
    uint256 MONT_REWARD_MANAGER_INITIAL_MONT_SUPPLY = 4_000_000_000e18;

    function run()
        public
        virtual
        broadcast
        returns (
            Burner burner,
            Revealer revealer,
            Vault vault,
            MontRewardManager montRewardManager,
            MONT mont,
            ERC20Custom usdc,
            TimelockController timeLockController,
            GameFactory gameFactory
        )
    {
        // todo: use env to check if we should create the USDC token or use its address
        usdc = new ERC20Custom(
            "USD Tether",
            "USDC",
            6,
            100_000_000,
            msg.sender
        );
        mont = new MONT(MONT_INITIAL_SUPPLY, msg.sender);

        Burner burnerImplementation = new Burner();
        TransparentUpgradeableProxy burnerProxy = new TransparentUpgradeableProxy(
                address(burnerImplementation),
                msg.sender,
                emptyByte
            );
        burner = Burner(address(burnerProxy));

        burner.initialize(mont, usdc, uniswapSwapRouter, MONT_USDC_POOL_FEE);
        // burner = new Burner(mont, usdc, uniswapSwapRouter, MONT_USDC_POOL_FEE);

        revealer = new Revealer();
        vault = new Vault(
            mont,
            usdc,
            burner,
            GameFactory(address(0)),
            IMontRewardManager(address(0)),
            MINIMUM_BET_AMOUNT
        );

        // GAME_FACTORY PROXY
        GameFactory gameFactoryImplementation = new GameFactory();
        TransparentUpgradeableProxy gameFactoryProxy = new TransparentUpgradeableProxy(
                address(gameFactoryImplementation),
                msg.sender,
                emptyByte
            );
        gameFactory = GameFactory(address(gameFactoryProxy));

        gameFactory.initialize(
            usdc,
            vault,
            address(revealer),
            GAME_DURATION,
            CLAIMABLE_AFTER,
            MAX_FREE_REVEALS,
            GAME_CREATION_FEE
        );

        montRewardManager = new MontRewardManager(
            address(vault),
            mont,
            usdc,
            gameFactory,
            uniswapV3Factory,
            MONT_USDC_POOL_FEE,
            TWAP_INTERVAL
        );
        timeLockController = new TimelockController(
            MIN_DELAY,
            EMPTY_ADDRESS_ARRAY,
            EMPTY_ADDRESS_ARRAY,
            msg.sender
        );

        vault.setMontRewardManager(montRewardManager);
        vault.setGameFactory(gameFactory);

        revealer.grantRole(revealer.REVEALER_ROLE(), revealer1);
        revealer.grantRole(revealer.REVEALER_ROLE(), revealer2);
        revealer.grantRole(revealer.REVEALER_ROLE(), revealer3);
        revealer.grantRole(revealer.REVEALER_ROLE(), revealer4);
        revealer.grantRole(revealer.REVEALER_ROLE(), revealer5);

        usdc.transfer(address(vault), VAULT_INITIAL_USDC_SUPPLY);
        mont.transfer(
            address(montRewardManager),
            MONT_REWARD_MANAGER_INITIAL_MONT_SUPPLY
        );

        vault.transferOwnership(address(timeLockController));
        gameFactory.transferOwnership(address(timeLockController));

        createPoolAndMintLiquidity(address(usdc), address(mont));

        console2.log("BURNER=%s", address(burner));
        console2.log("GAME_FACTORY=%s", address(gameFactoryProxy));
        console2.log("REVEALER=%s", address(revealer));
        console2.log("VAULT=%s", address(vault));
        console2.log("MONT_REWARD_MANAGER=%s", address(montRewardManager));
        console2.log("MONT=%s", address(mont));
        console2.log("USDC=%s", address(usdc));
        console2.log("TIME_LOCK_CONTROLLER=%s", address(timeLockController));
        console2.log("UNISWAP_V3_FACTORY=%s", address(uniswapV3Factory));
        console2.log("UNISWAP_V3_NFPM=%s", address(uniswapNFPM));
        console2.log("UNISWAP_V3_SWAP_ROUTER=%s", address(uniswapSwapRouter));
    }

    function createPoolAndMintLiquidity(
        address _usdc,
        address _mont
    ) public returns (address pool) {
        if (_usdc > _mont) {
            uint256 amount0 = 2_000_000_000e18;
            uint256 amount1 = 500_000e6;
            uint160 sqrt = 560_227_709_747_861_389_312;

            pool = createPool(_mont, _usdc, 3000, sqrt, amount0, amount1);
        } else {
            uint256 amount0 = 500_000e6;
            uint256 amount1 = 2_000_000_000e18;
            uint160 sqrt = 11_204_554_194_957_228_823_252_587_668_406_534_144;

            pool = createPool(_usdc, _mont, 3000, sqrt, amount0, amount1);
        }
    }
}
