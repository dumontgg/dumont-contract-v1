// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import {Game} from "./Game.sol";
import {Vault} from "./Vault.sol";
import {IGameFactory} from "./interfaces/IGameFactory.sol";

/**
 * @title GameFactory is used to create new games
 * @notice This contract can only be called by the Vault contract to create new games
 */
contract GameFactory is IGameFactory, Ownable2Step {
    uint256 public gameDuration;
    IERC20 public usdt;
    Vault public vault;
    address public server;

    /**
     * @notice Sets vault and server addresses
     * @param _usdt The address of the USDT token
     * @param _vault The vault address that will call the createGame
     * @param _server The server address that will be passed to each game
     * @param _gameDuration The duration of each game. Games expire after that period of time
     */
    constructor(IERC20 _usdt, Vault _vault, address _server, uint256 _gameDuration) {
        usdt = _usdt;
        vault = _vault;
        server = _server;
        gameDuration = _gameDuration;
    }

    /**
     * @notice Checks if the caller is the vault contract address to protect createGame function
     */
    modifier onlyVault() {
        if (msg.sender != address(vault)) {
            revert NotAuthorized(msg.sender);
        }

        _;
    }

    /**
     * @notice Sets a new duration for future games
     * @param _gameDuration The new duration of games by seconds
     */
    function setGameDuration(uint256 _gameDuration) external onlyOwner {
        emit GameDurationChanged(gameDuration, _gameDuration);

        gameDuration = _gameDuration;
    }

    /**
     * @notice Sets a new address for Vault
     * @param _vault New vault address
     */
    function setVault(Vault _vault) external onlyOwner {
        emit VaultChanged(address(vault), address(_vault));

        vault = _vault;
    }

    /**
     * @notice Sets a new address for server
     * @param _server New server address
     */
    function setServer(address _server) external onlyOwner {
        emit ServerChanged(server, _server);

        server = _server;
    }

    /**
     * @notice Creates a game with the specified parameters and returns the address of the game
     * @param _player The address of the player that called the Vault to create a game
     * @param _gameId Id of the game
     * @return gameAddress The address of the newly created game
     */
    function createGame(address _player, uint256 _gameId) external onlyVault returns (address gameAddress, address) {
        gameAddress = address(new Game(usdt, vault, server, _player, _gameId, gameDuration));

        emit GameCreated(_gameId, gameAddress, _player, gameDuration);

        return (gameAddress, server);
    }
}
