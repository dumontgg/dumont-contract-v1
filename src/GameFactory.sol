// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Game} from "./Game.sol";
import {IVault} from "./interfaces/IVault.sol";
import {Ownable} from "./libraries/Ownable.sol";
import {IGameFactory} from "./interfaces/IGameFactory.sol";

/**
 * @title GameFactory is used to create games
 * @author X team
 * @notice This contract is only called by Vault to create games
 */
contract GameFactory is IGameFactory, Ownable {
    IVault public vault;
    address public server;

    event VaultChanged(address indexed _from, address indexed _to);
    event ServerChanged(address indexed from, address indexed _to);
    event GameCreated(uint256 indexed gameId, address indexed _game, address indexed _player);

    // This is fired when the caller of createGame is not the Vault
    error NotAuthorized();

    /**
     * @notice Sets vault and server addresses
     * @param _vault The vault address that will call the createGame
     * @param _server The server address that will be passed to each game
     */
    constructor(IVault _vault, address _server) Ownable(msg.sender) {
        vault = _vault;
        server = _server;
    }

    /**
     * @notice Checks if the caller is the vault contract address to protect createGame function
     */
    modifier onlyVault() {
        if (msg.sender != address(vault)) {
            revert NotAuthorized();
        }

        _;
    }

    /**
     * @notice Sets a new address for Vault
     * @param _vault New vault address
     * @dev This function is only callable by the owner
     */
    function setVault(IVault _vault) external onlyOwner {
        emit VaultChanged(address(vault), address(_vault));

        vault = _vault;
    }

    /**
     * @notice Sets a new address for server
     * @param _server New server address
     * @dev This function is only callable by the owner
     */
    function setServer(address _server) external onlyOwner {
        emit ServerChanged(server, _server);

        server = _server;
    }

    /**
     * @notice Creates a game with the specified parameters and returns the address of the game
     * @param _player The address of the player that called the Vault to create a game
     * @param _gameId Id of the game
     * @return gameAddress The address of the created game
     */
    function createGame(address _player, uint256 _gameId) external onlyVault returns (address gameAddress) {
        // Server is passed so that the server can make changed to the game contract
        // Such as putting the hash of the Cards inside the contract to initialize the game
        Game g = new Game(vault, server, _player, _gameId, 12); // TODO: maxallowance should be changable by admins

        gameAddress = address(g);

        emit GameCreated(_gameId, gameAddress, _player);
    }
}
