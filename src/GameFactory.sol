// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Game} from "./Game.sol";
import {Vault} from "./Vault.sol";
import {IGameFactory} from "./interfaces/IGameFactory.sol";

/**
 * @title GameFactory Contract
 * @notice Facilitates the creation of new games
 * @dev This contract can only be called by the Vault contract to create new games
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
     * @notice Initializes the GameFactory contract with specified parameters
     * @param _usdt The address of the USDT token
     * @param _vault The address of the vault that will call the createGame function
     * @param _revealer A trusted address used to initialize games and reveal player guesses
     * @param _gameDuration The duration of each game, after which games expire
     * @param _gameCreationFee The fee required for players to create games
     */
    constructor(IERC20 _usdt, Vault _vault, address _revealer, uint256 _gameDuration, uint256 _gameCreationFee)
        Ownable(msg.sender)
    {
        usdt = _usdt;
        vault = _vault;
        revealer = _revealer;
        gameDuration = _gameDuration;
        gameCreationFee = _gameCreationFee;
    }

    /**
     * @notice Modifier to check if the caller is the Vault contract address
     */
    modifier onlyVault() {
        if (msg.sender != address(vault)) {
            revert NotAuthorized(msg.sender);
        }

        _;
    }

    /**
     * @notice Modifier to check if the caller is the player of the specified game
     * @param _gameId The ID of the game
     */
    modifier onlyPlayer(uint256 _gameId) {
        if (games[_gameId].player == msg.sender) {
            revert NotAuthorized(msg.sender);
        }

        _;
    }

    /**
     * @notice Changes the fee required to create a new game
     * @param _gameCreationFee The new fee amount in USDT
     */
    function setGameCreationFee(uint256 _gameCreationFee) external onlyOwner {
        emit GameFeeChanged(gameCreationFee, _gameCreationFee);

        gameCreationFee = _gameCreationFee;
    }

    /**
     * @notice Changes the duration of future games
     * @param _gameDuration The new duration in seconds
     */
    function setGameDuration(uint256 _gameDuration) external onlyOwner {
        emit GameDurationChanged(gameDuration, _gameDuration);

        gameDuration = _gameDuration;
    }

    /**
     * @notice Changes the address of the Vault contract
     * @param _vault The new Vault contract address
     */
    function setVault(Vault _vault) external onlyOwner {
        emit VaultChanged(address(vault), address(_vault));

        vault = _vault;
    }

    /**
     * @notice Changes the manager address for creating new games
     * @param _revealer The new manager address
     */
    function setRevealer(address _revealer) external onlyOwner {
        emit RevealerChanged(revealer, _revealer);

        revealer = _revealer;
    }

    /**
     * @notice Creates a new game using the GameFactory contract and stores related data
     * @dev The caller must pay at least the gameCreationFee amount to create a game
     * @return The ID of the newly created game
     */
    function createGame() external returns (uint256) {
        uint256 _gameId = gameId;

        usdt.safeTransferFrom(msg.sender, address(vault), gameCreationFee);

        address gameAddress = address(new Game(usdt, vault, revealer, msg.sender, _gameId, gameDuration));

        games[_gameId] = GameDetails({gameAddress: gameAddress, player: msg.sender, manager: revealer});

        emit GameCreated(_gameId, gameAddress, msg.sender, gameDuration);

        ++gameId;

        return _gameId;
    }

    /**
     * @notice Retrieves the details of a specific game
     * @param _gameId The ID of the game
     * @return Details of the specified game
     */
    function getGame(uint256 _gameId) external view returns (GameDetails memory) {
        return games[_gameId];
    }
}
