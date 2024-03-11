// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Game} from "./Game.sol";
import {Vault} from "./Vault.sol";
import {IGameFactory} from "./interfaces/IGameFactory.sol";

/**
 * @title GameFactory is used to create new games
 * @notice This contract can only be called by the Vault contract to create new games
 */
contract GameFactory is IGameFactory, Ownable2Step {
    using SafeERC20 for IERC20;

    IERC20 public usdt;
    Vault public vault;
    address public revealer;

    uint256 public gameDuration;
    uint256 public gameCreationFee;

    uint256 public gameId = 0;
    mapping(uint256 gameId => GameDetails gameDetails) public games;

    /**
     * @notice Sets addresses and duration of each game
     * @param _usdt The address of the USDT token
     * @param _vault The vault address that will call the createGame
     * @param _revealer A trusted address that will be passed to each game that will be used
     *  to initialize the game and reveal each card that the player guesses
     * @param _gameDuration The duration of each game. Games expire after that period of time
     * @param _gameCreationFee Sets the fee for players to create games
     */
    constructor(
        IERC20 _usdt,
        Vault _vault,
        address _revealer,
        uint256 _gameDuration,
        uint256 _gameCreationFee
    ) {
        usdt = _usdt;
        vault = _vault;
        revealer = _revealer;
        gameDuration = _gameDuration;
        gameCreationFee = _gameCreationFee;
    }

    /**
     * @notice Checks if the caller is the vault contract address
     */
    modifier onlyVault() {
        if (msg.sender != address(vault)) {
            revert NotAuthorized(msg.sender);
        }

        _;
    }

    /**
     * @notice Only player of the game can call Vault
     * @param _gameId Id of the game
     */
    modifier onlyPlayer(uint256 _gameId) {
        if (games[_gameId].player == msg.sender) {
            revert NotAuthorized(msg.sender);
        }

        _;
    }

    /**
     * @notice Changes the fee required to make a new game
     * @param _gameCreationFee The new amount of USDT needed to create a game
     */
    function setGameCreationFee(uint256 _gameCreationFee) external onlyOwner {
        emit GameFeeChanged(gameCreationFee, _gameCreationFee);

        gameCreationFee = _gameCreationFee;
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
     * @notice Sets a new manager for newly created games
     * @param _revealer New manager address
     */
    function setRevealer(address _revealer) external onlyOwner {
        emit RevealerChanged(revealer, _revealer);

        revealer = _revealer;
    }

    /**
     * @notice Creates a new game using the GameFactory contract and stores the related data
     * @dev The caller need to pay at least gameCreationFee amount to create a game
     */
    function createGame() external returns (uint256) {
        uint256 _gameId = gameId;

        usdt.safeTransferFrom(msg.sender, address(vault), gameCreationFee);

        address gameAddress = address(
            new Game(usdt, vault, revealer, msg.sender, _gameId, gameDuration)
        );

        games[_gameId] = GameDetails({
            gameAddress: gameAddress,
            player: msg.sender,
            manager: revealer
        });

        emit GameCreated(_gameId, gameAddress, msg.sender, gameDuration);

        ++gameId;

        return _gameId;
    }

    /**
     * @notice Returns a game
     * @param _gameId ID of the game
     * @return gameDetails Details of the game
     */
    function getGame(
        uint256 _gameId
    ) external view returns (GameDetails memory) {
        return games[_gameId];
    }
}
