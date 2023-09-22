// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";

import {DMN} from "../src/DMN.sol";
import {Vault} from "../src/Vault.sol";
import {Burner} from "../src/Burner.sol";
import {GameFactory} from "../src/GameFactory.sol";
import {IVault} from "../src/interfaces/IVault.sol";
import {ERC20} from "../src/interfaces/ERC20/ERC20.sol";
import {ISwapRouter} from "../src/interfaces/ISwapRouter.sol";

import {Users} from "./utils/Types.sol";

abstract contract BaseTest is Test {
    Users internal users;

    DMN internal dmn;
    ERC20 internal dai;
    Vault internal vault;
    Burner internal burner;
    GameFactory internal gameFactory;

    function setUp() public virtual {
        dmn = new DMN(100_000_000, address(this));
        dai = new ERC20("Dai Stablecoin", "DAI");
        // TODO: do something about ISwapRouter for Burner
        burner = new Burner(dmn, dai, ISwapRouter(address(this)), 3000);
        vault = new Vault(dmn, dai, burner, gameFactory, 1e15);
        gameFactory = new GameFactory(vault, address(this));

        // Set the correct address for GameFactory for Vault
        vault.setGameFactory(gameFactory);

        addLabels();

        users = Users({
            eve: createUser("Eve"),
            admin: createUser("Admin"),
            alice: createUser("Alice"),
            server: createUser("Server")
        });

        approveAdmin();
    }

    function addLabels() internal {
        vm.label({account: address(dmn), newLabel: "DMN"});
        vm.label({account: address(dai), newLabel: "DAI"});
        vm.label({account: address(vault), newLabel: "Vault"});
        vm.label({account: address(burner), newLabel: "Burner"});
        vm.label({account: address(gameFactory), newLabel: "GameFactory"});
    }

    /**
     * @notice Creates a new address, gives it a label, transfers ETH, DAI, and DMN to it
     * @param _name The name used to label the new address
     */
    function createUser(string memory _name) internal returns (address userAddress) {
        userAddress = makeAddr(_name);

        deal({to: userAddress, give: 100e18});
        deal({token: address(dmn), to: userAddress, give: 100e18});
        deal({token: address(dai), to: userAddress, give: 100_000_000e18});
    }

    /**
     * @dev Approves DAI to the Vault contract from the admin address
     */
    function approveAdmin() internal {
        changePrank({msgSender: users.admin});
        dai.approve(address(vault), type(uint256).max);
    }
}
