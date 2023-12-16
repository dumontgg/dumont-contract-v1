// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// TODO: is this right? Is should we use interface here?
import {Vault} from "../Vault.sol";

/**
 * @title GameFactory is used to create games
 * @author X team
 * @notice This contract is only called by Vault to create games
 */
interface IGameFactory {
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
