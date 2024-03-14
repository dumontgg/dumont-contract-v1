// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vault} from "../Vault.sol";

/**
 * @title GameFactory is used to create games
 * @notice This contract is only called by Vault to create games
 */
interface IGameFactory {
    struct GameDetails {
        address player;
        address manager;
        address gameAddress;
    }

    /**
     * @notice Emitted when game duration changes
     * @param _from The old game duration
     * @param _to The new game duration
     */
    event GameDurationChanged(uint256 _from, uint256 _to);

    /**
     * @notice Emitted when the address of the Vault changes
     * @param _from The old Vault address
     * @param _to The new Vault address
     */
    event VaultChanged(address indexed _from, address indexed _to);

    /**
     * @notice Emitted when the address of the revealer changes
     * @param _from The old revealer address
     * @param _to The new revealer address
     */
    event RevealerChanged(address indexed _from, address indexed _to);

    /**
     * @notice Emitted when
     */
    event GameFeeChanged(uint256 _from, uint256 _to);

    /**
     * @notice Emitted when a new Game is deployed
     * @param _gameId Unique ID of the game
     * @param _gameAddress Address of the game
     * @param _player Address of the player
     * @param _gameDuration Duration of the game
     */
    event GameCreated(
        uint256 indexed _gameId,
        address indexed _gameAddress,
        address indexed _player,
        uint256 _gameDuration
    );

    /**
     * @notice Thrown when the caller is not authorized
     * @param _caller Address of the caller of the transaction
     */
    error NotAuthorized(address _caller);

    /**
     * @notice Sets a new duration for future games
     * @param _gameDuration The new duration of games by seconds
     */
    function setGameDuration(uint256 _gameDuration) external;

    /**
     * @notice Sets a new address for Vault
     * @param _vault New vault address
     * @dev This function is only callable by the owner
     */
    function setVault(Vault _vault) external;

    /**
     * @notice Sets a new revealer for newly created games
     * @param _revealer New revealer address
     */
    function setRevealer(address _revealer) external;

    /**
     * @notice Creates a new game using the GameFactory contract and stores the related data
     * @dev The caller need to pay at least gameCreationFee amount to create a game
     */
    function createGame() external returns (uint256);

    /**
     * @notice Returns a game
     * @param _gameId ID of the game
     * @return gameDetails Details of the game
     */
    function getGame(uint256 _gameId) external returns (GameDetails memory);
}
