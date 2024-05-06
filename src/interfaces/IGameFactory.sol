// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vault} from "../Vault.sol";

/**
 * @title GameFactory Contract
 * @notice Facilitates the creation of new games
 * @dev This contract can only be called by the Vault contract to create new games
 */
interface IGameFactory {
    struct GameDetails {
        address player;
        address manager;
        address gameAddress;
    }

    /**
     * @notice Emitted when the game duration changes
     * @param _from The old game duration
     * @param _to The new game duration
     */
    event GameDurationChanged(uint256 indexed _from, uint256 indexed _to);

    /**
     * @notice Emitted when the claimable duration changes
     * @param _from The old claimable duration
     * @param _to The new claimable duration
     */
    event ClaimableAfterChanged(uint256 indexed _from, uint256 indexed _to);

    /**
     * @notice Emitted when the maximum free reveals change
     * @param _from The old maximum number
     * @param _to The new maximum number
     */
    event MaxFreeRevealsChanged(uint256 indexed _from, uint256 indexed _to);

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
     * @notice Emitted when the game creation fee changes
     * @param _from The old game creation fee
     * @param _to The new game creation fee
     */
    event GameFeeChanged(uint256 indexed _from, uint256 indexed _to);

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

    event Referred(address _referee, address _referrer, uint256 _timestamp);

    /**
     * @notice Thrown when the caller is not authorized
     * @param _caller Address of the caller of the transaction
     */
    error NotAuthorized(address _caller);

    error InvalidReferrer(address _referrer, address _referee);

    error ReferralAlreadySet(address _referee, address _referrer);

    /**
     * @notice Changes the fee required to create a new game
     * @param _gameCreationFee The new fee amount in USDT
     */
    function setGameCreationFee(uint256 _gameCreationFee) external;

    /**
     * @notice Changes the duration of future games
     * @param _gameDuration The new duration in seconds
     */
    function setGameDuration(uint256 _gameDuration) external;

    /**
     * @notice Changes the claimable duration of future games
     * @param _claimableAfter The new duration in seconds
     */
    function setClaimableAfter(uint256 _claimableAfter) external;

    /**
     * @notice Changes the maximum amount of free reveals a player can request for future games
     * @param _maxFreeReveals The amount of free reveals a player can request
     */
    function setMaxFreeReveals(uint256 _maxFreeReveals) external;

    /**
     * @notice Changes the address of the Vault contract
     * @param _vault The new Vault contract address
     */
    function setVault(Vault _vault) external;

    /**
     * @notice Changes the manager address for creating new games
     * @param _revealer The new manager address
     */
    function setRevealer(address _revealer) external;

    /**
     * @notice Creates a new game using the GameFactory contract and stores related data
     * @dev The caller must pay at least the gameCreationFee amount to create a game
     * @param _referrer The referrer of the player. Could be the 0x00 address if already set or
     * if the player does not want to set one
     * @return The ID and the address of the newly created game
     */
    function createGame(address _referrer) external returns (uint256, address);

    /**
     * @notice Retrieves the details of a specific game
     * @param _gameId The ID of the game
     * @return Details of the specified game
     */
    function getGame(
        uint256 _gameId
    ) external view returns (GameDetails memory);
}
