// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IBurner} from "./interfaces/IBurner.sol";
import {IGame} from "./interfaces/IGame.sol";
import {IGameFactory} from "./interfaces/IGameFactory.sol";
import {IMONT} from "./interfaces/IMONT.sol";
import {IRewardManager} from "./interfaces/IRewardManager.sol";
import {IVault} from "./interfaces/IVault.sol";

/**
 * @title Vault Contract
 * @notice Manages USDT deposits, withdrawals, and game rewards
 * @dev All deposits and withdrawals happen through this contract
 */
contract Vault is IVault, Ownable2Step {
    using SafeERC20 for IERC20;

    IMONT public mont;
    IERC20 public usdt;
    IBurner public burner;
    IGameFactory public gameFactory;
    IRewardManager public rewardManager;

    uint256 public minimumBetAmount;

    /**
     * @notice Constructor to set initial values
     * @param _mont Address of the Dumont token contract
     * @param _usdt Address of the USDT token contract
     * @param _burner Address of the burner contract used to sell USDT and burn MONT tokens
     * @param _gameFactory Address of the GameFactory contract
     * @param _rewardManager Address of the RewardManager contract
     * @param _minimumBetAmount Minimum amount of USDT that a player can place as a bet
     */
    constructor(
        IMONT _mont,
        IERC20 _usdt,
        IBurner _burner,
        IGameFactory _gameFactory,
        IRewardManager _rewardManager,
        uint256 _minimumBetAmount
    ) Ownable(msg.sender) {
        mont = _mont;
        usdt = _usdt;
        burner = _burner;
        gameFactory = _gameFactory;
        rewardManager = _rewardManager;
        minimumBetAmount = _minimumBetAmount;
    }

    /**
     * @notice Modifier to restrict access to game contracts only
     * @param _gameId Id of the game
     */
    modifier onlyGame(uint256 _gameId) {
        if (gameFactory.getGame(_gameId).manager != msg.sender) {
            revert NotAuthorized();
        }

        _;
    }

    /**
     * @notice Changes the address of the Burner contract
     * @param _burner The new address of the Burner contract
     */
    function setBurner(IBurner _burner) external onlyOwner {
        emit BurnerChanged(address(burner), address(_burner));

        burner = _burner;
    }

    /**
     * @notice Changes the address of the GameFactory contract
     * @param _gameFactory The new address of the GameFactory contract
     */
    function setGameFactory(IGameFactory _gameFactory) external onlyOwner {
        emit GameFactoryChanged(address(gameFactory), address(_gameFactory));

        gameFactory = _gameFactory;
    }

    /**
     * @notice Changes the address of the RewardManager contract
     * @param _rewardManager The address of the new RewardManager contract
     */
    function setRewardManager(IRewardManager _rewardManager) external onlyOwner {
        emit RewardManagerChanged(address(rewardManager), address(_rewardManager));

        rewardManager = _rewardManager;
    }

    /**
     * @notice Allows admins to deposit USDT into the contract
     * @param _amount The amount of USDT to deposit
     */
    function deposit(uint256 _amount) external {
        usdt.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Allows the owner to withdraw a specified amount of tokens
     * @param _token The address of the ERC20 token to withdraw
     * @param _amount The amount of tokens to withdraw
     * @param _recipient The address to receive the withdrawn tokens
     */
    function withdraw(address _token, uint256 _amount, address _recipient) external onlyOwner {
        IERC20(_token).safeTransfer(_recipient, _amount);

        emit Withdraw(_token, _amount, _recipient);
    }

    /**
     * @notice Allows the owner to withdraw ETH from the contract
     * @param _recipient The address to receive the withdrawn ETH
     */
    function withdrawETH(address _recipient) external onlyOwner {
        uint256 balance = address(this).balance;

        (bool success,) = _recipient.call{value: balance}("");

        if (!success) {
            revert FailedToSendEther();
        }
    }

    /**
     * @notice Notifies the Vault contract that a player lost a bet and sends USDT if player is the winner
     * @param _gameId Id of the game
     * @param _betAmount Amount of the bet in USDT
     * @param _totalAmount Amount of the bet multiplied by the odds
     * @param _player The address of the player
     * @param _isPlayerWinner cc
     */
    function notifyGameOutcome(
        uint256 _gameId,
        uint256 _betAmount,
        uint256 _totalAmount,
        address _player,
        bool _isPlayerWinner
    ) external onlyGame(_gameId) {
        uint256 burnAmount = (_betAmount * 8) / 100;

        if (_isPlayerWinner) {
            burnAmount = (_totalAmount * 8) / 100;

            uint256 reward = _totalAmount - ((_totalAmount - _betAmount) / 10);
            usdt.safeTransfer(_player, reward);
        }

        usdt.safeTransfer(address(burner), burnAmount);

        rewardManager.transferRewards(_betAmount, _totalAmount, _player, _isPlayerWinner);
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
     * @notice Returns the maximum bet amount a player can place
     */
    function getMaximumBetAmount() public view returns (uint256) {
        uint256 usdtAmount = usdt.balanceOf(address(this));

        return (usdtAmount * 2) / 100;
    }

    /**
     * @notice Returns the minimum bet amount a player can place
     */
    function getMinimumBetAmount() public view returns (uint256) {
        return minimumBetAmount;
    }
}
