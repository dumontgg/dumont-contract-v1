// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// TODO: is this right? Is should we use interface here?
import {Vault} from "../Vault.sol";

/**
 * @title GameFactory is used to create games
 * @notice This contract is only called by Vault to create games
 */
interface IGameFactory {
    event GameDurationChanged(uint256 _from, uint256 _to);
    event VaultChanged(address indexed _from, address indexed _to);
    event ServerChanged(address indexed from, address indexed _to);
    event GameCreated(uint256 indexed gameId, address indexed _game, address indexed _player, uint256 _gameDuration);

    error NotAuthorized(address _caller);

    /**
     * @notice Sets a new address for Vault
     * @param _vault New vault address
     * @dev This function is only callable by the owner
     */
    function setVault(Vault _vault) external;

    /**
     * @notice Sets a new address for server
     * @param _server New server address
     * @dev This function is only callable by the owner
     */
    function setServer(address _server) external;

    /**
     * @notice Creates a game with the specified parameters and returns the address of the game
     * @param _player The address of the player that called the Vault to create a game
     * @param _gameId Id of the game
     * @return gameAddress The address of the created game
     */
    function createGame(address _player, uint256 _gameId) external returns (address gameAddress, address);
}
