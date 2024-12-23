// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IBurner} from "./interfaces/IBurner.sol";
import {IGame} from "./interfaces/IGame.sol";
import {IGameFactory} from "./interfaces/IGameFactory.sol";
import {IMONT} from "./interfaces/IMONT.sol";
import {IMontRewardManager} from "./interfaces/IMontRewardManager.sol";
import {IVault} from "./interfaces/IVault.sol";

/**
 * @title Vault Contract
 * @notice Manages USDC deposits, withdrawals, and game rewards
 * @dev All deposits and withdrawals happen through this contract
 */
contract Vault is IVault, Ownable {
    using SafeERC20 for IERC20;

    /// @notice Address of ETH, used for events
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Address of the MONT token
    IMONT public immutable mont;
    /// @notice Address of the USDC token
    IERC20 public immutable usdc;
    /// @notice Address of the Burner contract
    IBurner public burner;
    /// @notice Address of the GameFactory contract
    IGameFactory public gameFactory;
    /// @notice Address of the MontRewardManager contract
    IMontRewardManager public montRewardManager;

    /// @notice Maximum total bet amount in percentage. Default is 200, means 2%
    uint256 public maximimBetRate;
    /// @notice Minimum bet amount. Default is 1000000, means 1 USDC
    uint256 public minimumBetAmount;

    /**
     * @notice Constructor to set initial values
     * @param _mont Address of the Dumont token contract
     * @param _usdc Address of the USDC token contract
     * @param _burner Address of the burner contract used to sell USDC and burn MONT tokens
     * @param _gameFactory Address of the GameFactory contract
     * @param _montRewardManager Address of the RewardManager contract
     * @param _minimumBetAmount Minimum amount of USDC that a player can place as a bet
     */
    constructor(
        IMONT _mont,
        IERC20 _usdc,
        IBurner _burner,
        IGameFactory _gameFactory,
        IMontRewardManager _montRewardManager,
        uint256 _minimumBetAmount
    ) Ownable(msg.sender) {
        mont = _mont;
        usdc = _usdc;
        burner = _burner;
        maximimBetRate = 200;
        gameFactory = _gameFactory;
        minimumBetAmount = _minimumBetAmount;
        montRewardManager = _montRewardManager;
    }

    /**
     * @notice Changes the address of the Burner contract
     * @param _burner The new address of the Burner contract
     * @dev Emits BurnerChanged event
     */
    function setBurner(IBurner _burner) external onlyOwner {
        emit BurnerChanged(address(burner), address(_burner));

        burner = _burner;
    }

    /**
     * @notice Changes the address of the GameFactory contract
     * @param _gameFactory The new address of the GameFactory contract
     * @dev Emits GameFactoryChanged event
     */
    function setGameFactory(IGameFactory _gameFactory) external onlyOwner {
        emit GameFactoryChanged(address(gameFactory), address(_gameFactory));

        if (address(gameFactory) != address(0)) {
            revert GameFactoryAlreadySet();
        }

        gameFactory = _gameFactory;
    }

    /**
     * @notice Changes the address of the MontRewardManager contract
     * @param _montRewardManager The address of the new MontRewardManager contract
     * @dev Emits RewardManagerChanged event
     */
    function setMontRewardManager(IMontRewardManager _montRewardManager) external onlyOwner {
        emit RewardManagerChanged(address(montRewardManager), address(_montRewardManager));

        montRewardManager = _montRewardManager;
    }

    /**
     * @notice Allows admins to deposit USDC into the contract
     * @param _amount The amount of USDC to deposit
     * @dev Emits Deposited event
     */
    function deposit(uint256 _amount) external onlyOwner {
        usdc.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposited(_amount);
    }

    /**
     * @notice Allows the owner to withdraw a specified amount of tokens
     * @param _token The address of the ERC20 token to withdraw
     * @param _amount The amount of tokens to withdraw
     * @param _recipient The address to receive the withdrawn tokens
     * @dev Emits Withdrawn event
     */
    function withdraw(address _token, uint256 _amount, address _recipient) external onlyOwner {
        IERC20(_token).safeTransfer(_recipient, _amount);

        emit Withdrawn(_token, _amount, _recipient);
    }

    /**
     * @notice Allows the owner to withdraw ETH from the contract
     * @param _recipient The address to receive the withdrawn ETH
     * @dev Emits Withdrawn event
     */
    function withdrawETH(address _recipient) external onlyOwner {
        uint256 balance = address(this).balance;

        (bool success,) = _recipient.call{value: balance}("");

        if (!success) {
            revert FailedToSendEther();
        }

        emit Withdrawn(ETH, balance, _recipient);
    }

    /**
     * @notice Notifies the Vault contract that a player lost a bet and sends USDC if player is the winner
     * @param _gameId Id of the game
     * @param _betAmount Amount of the bet in USDC
     * @param _totalAmount Amount of the bet multiplied by the odds
     * @param _houseEdgeAmount The house edge amount reducted from the total amount if the player wins
     * @param _isPlayerWinner Whether or not the player won or not
     * @dev Emits PlayerRewardsTransferred event
     */
    function transferPlayerRewards(
        uint256 _gameId,
        uint256 _betAmount,
        uint256 _totalAmount,
        uint256 _houseEdgeAmount,
        bool _isPlayerWinner
    ) external {
        IGameFactory.GameDetails memory game = gameFactory.games(_gameId);

        if (game.gameAddress != msg.sender) {
            revert NotAuthorized(msg.sender);
        }

        uint256 houseEdge = _betAmount / 10;

        if (_isPlayerWinner) {
            houseEdge = _houseEdgeAmount;
        }

        uint256 burnAmount = (houseEdge * 8) / 10;

        usdc.safeTransfer(address(burner), burnAmount);

        if (_isPlayerWinner) {
            usdc.safeTransfer(game.player, _totalAmount);

            emit PlayerRewardsTransferred(game.player, _totalAmount);
        }

        montRewardManager.transferPlayerRewards(_betAmount, _totalAmount, houseEdge, game.player, _isPlayerWinner);
    }

    /**
     * @notice Changes the minimum bet amount of USDC
     * @param _minimumBetAmount The new minimum bet amount
     * @dev Emits MinimumBetAmountChanged event
     */
    function setMinimumBetAmount(uint256 _minimumBetAmount) external onlyOwner {
        emit MinimumBetAmountChanged(minimumBetAmount, _minimumBetAmount);

        minimumBetAmount = _minimumBetAmount;
    }

    /**
     * @notice Changes the percentage of USDC in the Vault that can be sent as the reward
     * @param _maximumBetRate The new maximim bet rate
     * @dev Emits MaximumBetRateChanged event
     */
    function setMaximumBetRate(uint256 _maximumBetRate) external onlyOwner {
        emit MaximumBetRateChanged(maximimBetRate, _maximumBetRate);

        maximimBetRate = _maximumBetRate;
    }

    /**
     * @notice Returns the maximum bet amount a player can place
     */
    function getMaximumBetAmount() external view returns (uint256) {
        uint256 usdcAmount = usdc.balanceOf(address(this));

        return (usdcAmount * maximimBetRate) / 10000;
    }

    /**
     * @notice Returns the minimum bet amount a player can place
     */
    function getMinimumBetAmount() external view returns (uint256) {
        return minimumBetAmount;
    }

    receive() external payable {}
}
