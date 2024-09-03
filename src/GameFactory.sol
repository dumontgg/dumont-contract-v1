// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Game} from "./Game.sol";
import {Vault} from "./Vault.sol";
import {IGameFactory} from "./interfaces/IGameFactory.sol";

/**
 * @title GameFactory Contract
 * @notice Facilitates the creation of new games
 */
contract GameFactory is IGameFactory, OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice This uses 6 decimals because the contract uses USDT as the fee token
    uint256 public constant MAXIMUM_GAME_CREATION_FEE = 10e6;

    /// @notice Address of the USDT token
    IERC20 public usdt;
    /// @notice Address of the Vault contract
    Vault public vault;
    /// @notice Address of the Revealer contract
    address public revealer;
    /// @notice Duration of newly created games
    uint256 public gameDuration;
    /// @notice Duration at which the revealer can reveal the cards of newly created games
    uint256 public claimableAfter;
    /// @notice Maximum amount of free reveals for newly created games
    uint256 public maxFreeReveals;
    /// @notice Fee of game creation in USDT
    uint256 public gameCreationFee;
    /// @notice ID of the next Game
    uint256 public nextGameId = 0;

    /// @notice Number of games a user has created
    mapping(address user => uint256 games) public userGames;
    /// @notice Referrals program
    mapping(address referee => address referrer) public referrals;
    /// @notice Number of players a referrer has invited
    mapping(address referrer => uint256 invites) public referrerInvites;
    mapping(uint256 gameId => GameDetails gameDetails) private _games;

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
    function initialize(
        IERC20 _usdt,
        Vault _vault,
        address _revealer,
        uint256 _gameDuration,
        uint256 _claimableAfter,
        uint256 _maxFreeReveals,
        uint256 _gameCreationFee
    ) external initializer {
        usdt = _usdt;
        vault = _vault;
        revealer = _revealer;
        gameDuration = _gameDuration;
        claimableAfter = _claimableAfter;
        maxFreeReveals = _maxFreeReveals;
        gameCreationFee = _gameCreationFee;

        __Ownable_init(msg.sender);
    }

    /**
     * @notice Pauses the GameFactory from creating new games
     * @dev Emits Paused event
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the GameFactory from creating new games
     * @dev Emits Unpaused event
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Changes the fee required to create a new game
     * @param _gameCreationFee The new fee amount in USDT
     * @dev Emits GameFeeChanged event
     */
    function setGameCreationFee(uint256 _gameCreationFee) external onlyOwner {
        if (_gameCreationFee > MAXIMUM_GAME_CREATION_FEE) {
            revert GameCreationFeeIsTooHigh(_gameCreationFee, MAXIMUM_GAME_CREATION_FEE);
        }

        emit GameFeeChanged(gameCreationFee, _gameCreationFee);

        gameCreationFee = _gameCreationFee;
    }

    /**
     * @notice Changes the duration of future games
     * @param _gameDuration The new duration in seconds
     * @dev Emits GameDurationChanged event
     */
    function setGameDuration(uint256 _gameDuration) external onlyOwner {
        emit GameDurationChanged(gameDuration, _gameDuration);

        gameDuration = _gameDuration;
    }

    /**
     * @notice Changes the claimable duration of future games
     * @param _claimableAfter The new duration in seconds
     * @dev Emits ClaimableAfterChanged event
     */
    function setClaimableAfter(uint256 _claimableAfter) external onlyOwner {
        emit ClaimableAfterChanged(claimableAfter, _claimableAfter);

        claimableAfter = _claimableAfter;
    }

    /**
     * @notice Changes the maximum amount of free reveals a player can request for future games
     * @param _maxFreeReveals The amount of free reveals a player can request
     * @dev Emits MaxFreeRevealsChanged event
     */
    function setMaxFreeReveals(uint256 _maxFreeReveals) external onlyOwner {
        emit MaxFreeRevealsChanged(maxFreeReveals, _maxFreeReveals);

        maxFreeReveals = _maxFreeReveals;
    }

    /**
     * @notice Changes the manager address for creating new games
     * @param _revealer The new manager address
     * @dev Emits RevealerChanged event
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
     * @dev Emits GameCreated event
     * @return id The ID of the newly created game
     * @return gameAddress The address of the newly created game
     */
    function createGame(address _referrer) external whenNotPaused returns (uint256 id, address gameAddress) {
        uint256 _gameId = nextGameId;

        if (gameCreationFee > 0) {
            usdt.safeTransferFrom(msg.sender, address(vault), gameCreationFee);
        }

        id = _gameId;
        gameAddress =
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

        ++nextGameId;
        userGames[msg.sender] += 1;

        setReferrer(msg.sender, _referrer);

        emit GameCreated(_gameId, gameAddress, msg.sender);

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
        if (_referrer == address(0) || referrals[_referee] == _referrer) {
            return;
        }

        if (_referrer == _referee) {
            return;
            // revert InvalidReferrer(_referrer, _referee);
        }

        if (referrals[_referee] != address(0)) {
            return;
            // revert ReferralAlreadySet(_referee, referrals[_referee]);
        }

        referrals[_referee] = _referrer;
        referrerInvites[_referrer] += 1;

        emit Referred(_referee, _referrer);
    }
}
