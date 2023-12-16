// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import {Game} from "./Game.sol";
import {Vault} from "./Vault.sol";
import {IGameFactory} from "./interfaces/IGameFactory.sol";

/**
 * @title GameFactory is used to create games
 * @author X team
 * @notice This contract is only called by Vault to create games
 */
contract GameFactory is IGameFactory, Ownable2Step {
    uint256 public gameDuration;

    IERC20 public dai;
    Vault public vault;
    address public server;

    event GameDurationChanged(uint256 _from, uint256 _to);
    event VaultChanged(address indexed _from, address indexed _to);
    event ServerChanged(address indexed from, address indexed _to);
    event GameCreated(uint256 indexed gameId, address indexed _game, address indexed _player, uint256 _gameDuration);

    error NotAuthorized();

    /**
     * @notice Sets vault and server addresses
     * @param _dai The address of the DAI ERC20 token
     * @param _vault The vault address that will call the createGame
     * @param _server The server address that will be passed to each game
     * @param _gameDuration The duration of the game
     * game will be unplayable when this time passes after game creation date
     */
    constructor(IERC20 _dai, Vault _vault, address _server, uint256 _gameDuration) {
        dai = _dai;
        vault = _vault;
        server = _server;
        gameDuration = _gameDuration;
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
     * @notice Sets a new gameDuration for a games
     * @param _gameDuration The new duration of the game by seconds
     * @dev This function is only callable by the owner
     */
    function setGameDuration(uint256 _gameDuration) external onlyOwner {
        emit GameDurationChanged(gameDuration, _gameDuration);

        gameDuration = _gameDuration;
    }

    /**
     * @notice Sets a new address for Vault
     * @param _vault New vault address
     * @dev This function is only callable by the owner
     */
    function setVault(Vault _vault) external onlyOwner {
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
    function createGame(address _player, uint256 _gameId) external onlyVault returns (address gameAddress, address) {
        gameAddress = address(new Game(dai, vault, server, _player, _gameId, gameDuration));

        emit GameCreated(_gameId, gameAddress, _player, gameDuration);

        return (gameAddress, server);
    }
}
