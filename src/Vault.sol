// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IBurner} from "./interfaces/IBurner.sol";
import {IGame} from "./interfaces/IGame.sol";
import {IGameFactory} from "./interfaces/IGameFactory.sol";
import {IMONT} from "./interfaces/IMONT.sol";
import {IRewardManager} from "./interfaces/IRewardManager.sol";
import {IVault} from "./interfaces/IVault.sol";

/**
 * @notice That vault contract that stores USDT and manages other contracts
 * @author X team
 * @notice The vault is used to create games, and all deposits and withdrawals happen
 */
contract Vault is IVault, Ownable2Step {
    using SafeERC20 for IERC20;

    IMONT public mont;
    IERC20 public usdt;
    IBurner public burner;
    IGameFactory public gameFactory;
    IRewardManager public rewardManager;

    uint256 public gameId = 0;
    uint256 public gameCreationFee = 1e18;
    uint256 public minimumBetAmount = 1e18;
    mapping(uint256 gameId => GameDetails gameDetails) public games;

    /**
     * @notice Sets contract addresses and gameFee
     * @param _mont Address of the Dumont token
     * @param _usdt The address of the USDT token
     * @param _burner Address of the burner token used to sell USDT and burn MONT tokens
     * @param _gameFactory Address of the GameFactory contract
     * @param _rewardManager Address of the RewardManager contract
     * @param _gameCreationFee Sets the fee for players to create games
     */
    constructor(
        IMONT _mont,
        IERC20 _usdt,
        IBurner _burner,
        IGameFactory _gameFactory,
        IRewardManager _rewardManager,
        uint256 _gameCreationFee
    ) {
        mont = _mont;
        usdt = _usdt;
        burner = _burner;
        gameFactory = _gameFactory;
        rewardManager = _rewardManager;
        gameCreationFee = _gameCreationFee;
    }

    /**
     * @notice Only player of the game can call Vault
     * @param _gameId Id of the game
     */
    modifier onlyPlayer(uint256 _gameId) {
        if (games[_gameId].player == msg.sender) {
            revert NotAuthorized();
        }

        _;
    }

    /**
     * @notice Only game contracts can call Vault
     * @param _gameId Id of the game
     */
    modifier onlyGame(uint256 _gameId) {
        if (games[_gameId].manager != msg.sender) {
            revert NotAuthorized();
        }

        _;
    }

    /**
     * @notice Changes the minimum bet amount of USDT
     * @param _minimumBetAmount The new minimum bet amount
     */
    function setMinimumBetAmount(uint256 _minimumBetAmount) external onlyOwner {
        emit MinimumBetAmountChanged(minimumBetAmount, _minimumBetAmount);

        minimumBetAmount = _minimumBetAmount;
    }

    /**
     * @notice Changes the address of Burner contract
     * @param _burner The new address of the Burner contract
     */
    function setBurner(IBurner _burner) external onlyOwner {
        emit BurnerChanged(address(burner), address(_burner));

        burner = _burner;
    }

    /**
     * @notice Changes the address of GameFactory contract
     * @param _gameFactory The new address of the GameFactory contract
     */
    function setGameFactory(IGameFactory _gameFactory) external onlyOwner {
        emit GameFactoryChanged(address(gameFactory), address(_gameFactory));

        gameFactory = _gameFactory;
    }

    /**
     * @notice Changes the address of rewardManager contract
     * @param _rewardManager The address of the new RewardManager contract
     */
    function setRewardManager(
        IRewardManager _rewardManager
    ) external onlyOwner {
        emit RewardManagerChanged(
            address(rewardManager),
            address(_rewardManager)
        );

        rewardManager = _rewardManager;
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
     * @notice Deposits USDT into the contract
     * @param _amount The amount of USDT to deposit
     * @dev Should be called by the admins of the protocol
     */
    function depositAdmin(uint256 _amount) external {
        usdt.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Withdraws an amount of a specific token, usually USDT or MONT
     * @param _token The ERC20 token to withdraw
     * @param _amount The amount of token to withdraw
     * @param _recipient The destination address that will receive the tokens
     * @dev This can only be called by the owner of the contract
     */
    function withdrawToken(
        address _token,
        uint256 _amount,
        address _recipient
    ) external onlyOwner {
        IERC20(_token).safeTransfer(_recipient, _amount);

        emit Withdraw(_token, _amount, _recipient);
    }

    /**
     * @notice Withdraws ETH from the contract and transfers it to the recipient
     * @param _recipient The destination address that will receive ETH
     * @dev ETH gets stored when the createGame function is called
     * and this function can only be called by the owner
     */
    function withdrawETH(address _recipient) external onlyOwner {
        uint256 balance = address(this).balance;

        (bool success, ) = _recipient.call{value: balance}("");

        if (!success) {
            revert FailedToSendEther();
        }
    }

    /**
     * @notice Creates a new game using the GameFactory contract and stores the related data
     * @dev The caller need to pay at least gameCreationFee amount to create a game
     */
    function createGame() external returns (uint256) {
        uint256 _gameId = gameId;

        usdt.safeTransferFrom(msg.sender, address(this), gameCreationFee);

        (address gameAddress, address manager) = gameFactory.createGame(
            msg.sender,
            _gameId
        );

        games[_gameId] = GameDetails({
            gameAddress: gameAddress,
            player: msg.sender,
            manager: manager
        });

        emit GameCreated(_gameId, gameAddress, msg.sender);

        ++gameId;

        return _gameId;
    }

    /**
     * @notice Notifies the Vault that the player lost a bet
     * @param _gameId Id of the game
     * @param _betAmount Amount of the bet times the rate
     * @param _betOdds Guess number of the player
     */
    function playerLostGame(
        uint256 _gameId,
        uint256 _betAmount,
        uint256 _betOdds,
        address _player
    ) external onlyGame(_gameId) {
        transferMontReward(_betAmount, _betOdds, _player, false);
    }

    function playerWonGame(
        uint256 _gameId,
        uint256 _betAmount,
        uint256 _betOdds,
        address _player
    ) external onlyGame(_gameId) {
        // give player some amount of MONT based on their bet_amount
        // transfer bet_amount to player
        transferMontReward(_betAmount, _betOdds, _player, true);
    }

    function transferMontReward(
        uint256 _betAmount,
        uint256 _betOdds,
        address _player,
        bool _isPlayerWinner
    ) private {
        rewardManager.transferRewards(
            _betAmount,
            _betOdds,
            _isPlayerWinner,
            _player
        );
    }

    /**
     * @notice Returns the maximum bet amount a player can place
     */
    function getMaximumBetAmount() public view returns (uint256) {
        uint256 usdtAmount = usdt.balanceOf(address(this));

        // TODO: Calculate temporary amount too
        return (usdtAmount * 2) / 100;
    }
}
