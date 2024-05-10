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

    IERC20 public immutable usdt;
    Vault public immutable vault;

    address public revealer;
    uint256 public gameDuration;
    uint256 public claimableAfter;
    uint256 public maxFreeReveals;
    uint256 public gameCreationFee;

    uint256 public gameId = 0;
    mapping(address user => uint256 games) public userGames;
    mapping(address referee => address referrer) public referrals;
    mapping(address referrer => uint256 invites) public referrerInvites;
    mapping(uint256 gameId => GameDetails gameDetails) private _games;

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
        if (_games[_gameId].player == msg.sender) {
            revert NotAuthorized(msg.sender);
        }

        _;
    }

    /**
     * @notice Initializes the GameFactory contract with specified parameters
     * @param _usdt The address of the USDT token
     * @param _vault The address of the vault that will call the createGame function
     * @param _revealer A trusted address used to initialize games and reveal player guesses
     * @param _gameDuration The duration of each game, after which games expire
     * @param _claimableAfter The duration which the user can claim their win if revealer does not reveal
     * @param _gameCreationFee The fee required for players to create games
     * @param _maxFreeReveals The maximum amount of free reveals a player can request
     */
    constructor(
        IERC20 _usdt,
        Vault _vault,
        address _revealer,
        uint256 _gameDuration,
        uint256 _claimableAfter,
        uint256 _maxFreeReveals,
        uint256 _gameCreationFee
    ) Ownable(msg.sender) {
        usdt = _usdt;
        vault = _vault;
        revealer = _revealer;
        gameDuration = _gameDuration;
        claimableAfter = _claimableAfter;
        maxFreeReveals = _maxFreeReveals;
        gameCreationFee = _gameCreationFee;
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
     * @notice Changes the claimable duration of future games
     * @param _claimableAfter The new duration in seconds
     */
    function setClaimableAfter(uint256 _claimableAfter) external onlyOwner {
        emit ClaimableAfterChanged(claimableAfter, _claimableAfter);

        claimableAfter = _claimableAfter;
    }

    /**
     * @notice Changes the maximum amount of free reveals a player can request for future games
     * @param _maxFreeReveals The amount of free reveals a player can request
     */
    function setMaxFreeReveals(uint256 _maxFreeReveals) external onlyOwner {
        emit MaxFreeRevealsChanged(maxFreeReveals, _maxFreeReveals);

        maxFreeReveals = _maxFreeReveals;
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
     * @param _referrer The referrer of the player. Could be the 0x00 address if already set or
     * if the player does not want to set one
     * @return The ID of the newly created game
     */
    function createGame(address _referrer) external returns (uint256, address) {
        uint256 _gameId = gameId;

        usdt.safeTransferFrom(msg.sender, address(vault), gameCreationFee);

        address gameAddress =
            address(new Game(usdt, vault, revealer, msg.sender, _gameId, gameDuration, claimableAfter, maxFreeReveals));

        _games[_gameId] = GameDetails({
            gameAddress: gameAddress,
            player: msg.sender,
            revealer: revealer,
            gameDuration: gameDuration,
            claimableAfter: claimableAfter,
            maxFreeReveals: maxFreeReveals,
            gameCreationFee: gameCreationFee,
            gameCreatedAt: block.timestamp
        });

        ++gameId;
        userGames[msg.sender] += 1;

        emit GameCreated(_gameId, gameAddress, msg.sender);

        if (_referrer != address(0)) {
            setReferrer(msg.sender, _referrer);
        }

        return (_gameId, gameAddress);
    }

    /**
     * @notice Retrieves the details of a specific game
     * @param _gameId The ID of the game
     * @return Details of the specified game
     */
    function games(uint256 _gameId) external view returns (GameDetails memory) {
        return _games[_gameId];
    }

    /**
     * @notice Sets the referrer for a player (referee)
     * @param _referee The player who chose the link of the referrer
     * @param _referrer The player who invited the referee
     */
    function setReferrer(address _referee, address _referrer) private {
        if (_referrer == _referee) {
            revert InvalidReferrer(_referrer, _referee);
        }

        if (referrals[_referee] != address(0)) {
            revert ReferralAlreadySet(_referee, referrals[_referee]);
        }

        referrals[_referee] = _referrer;
        referrerInvites[_referrer] += 1;

        emit Referred(_referee, _referrer);
    }
}
