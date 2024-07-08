// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IBurner} from "./IBurner.sol";
import {IGameFactory} from "./IGameFactory.sol";
import {IMontRewardManager} from "./IMontRewardManager.sol";

/**
 * @title Vault Contract
 * @notice Manages USDT deposits, withdrawals, and game rewards
 */
interface IVault {
    /**
     * @notice Emitted when the address of the Burner contract changes
     * @param _from The old Burner contract address
     * @param _to The new Burner contract address
     */
    event BurnerChanged(address indexed _from, address indexed _to);

    /**
     * @notice Emitted when the player received USDT by guessing a card correctly
     * @param _player The player address that received the reward
     * @param _rewards The amount of USDT rewards that the player received
     */
    event PlayerRewardsTransferred(address indexed _player, uint256 _rewards);

    /**
     * @notice Emitted when the address of the GameFactory contract changes
     * @param _from The old GameFactory contract address
     * @param _to The new GameFactory contract address
     */
    event GameFactoryChanged(address indexed _from, address indexed _to);

    /**
     * @notice Emitted when the address of the RewardManager contract changes
     * @param _from The old RewardManager contract address
     * @param _to The new RewardManager contract address
     */
    event RewardManagerChanged(address indexed _from, address indexed _to);

    /**
     * @notice Emitted when a deposit is made into the Vault
     * @param _amount The amount deposited
     */
    event Deposited(uint256 _amount);

    /**
     * @notice Emitted when the minimum bet amount is changed
     * @param _from The old minimum bet amount
     * @param _to The new minimum bet amount
     */
    event MinimumBetAmountChanged(uint256 _from, uint256 _to);

    /**
     * @notice Emitted when a withdrawal is made from the Vault
     * @param _token The address of the token being withdrawn
     * @param _amount The amount being withdrawn
     * @param _recipient The address receiving the withdrawal
     */
    event Withdrawn(address indexed _token, uint256 _amount, address indexed _recipient);

    /**
     * @notice Emitted when the maximum bet rate is changed
     * @param _from The old maximum rate
     * @param _to The new maximum rate
     */
    event MaximumBetRateChanged(uint256 _from, uint256 _to);

    /**
     * @notice Thrown when the caller is not authorized to perform an action
     * @param _caller Caller of the function
     */
    error NotAuthorized(address _caller);

    /**
     * @notice Thrown when an attempt to send ether fails
     */
    error FailedToSendEther();

    /**
     * @notice Changes the address of the Burner contract
     * @param _burner The new address of the Burner contract
     */
    function setBurner(IBurner _burner) external;

    /**
     * @notice Changes the address of the GameFactory contract
     * @param _gameFactory The new address of the GameFactory contract
     */
    function setGameFactory(IGameFactory _gameFactory) external;

    /**
     * @notice Changes the address of the MontRewardManager contract
     * @param _montRewardManager The address of the new MontRewardManager contract
     */
    function setMontRewardManager(IMontRewardManager _montRewardManager) external;

    /**
     * @notice Allows admins to deposit USDT into the contract
     * @param _amount The amount of USDT to deposit
     */
    function deposit(uint256 _amount) external;

    /**
     * @notice Allows the owner to withdraw a specified amount of tokens
     * @param _token The address of the ERC20 token to withdraw
     * @param _amount The amount of tokens to withdraw
     * @param _recipient The address to receive the withdrawn tokens
     */
    function withdraw(address _token, uint256 _amount, address _recipient) external;

    /**
     * @notice Allows the owner to withdraw ETH from the contract
     * @param _recipient The address to receive the withdrawn ETH
     */
    function withdrawETH(address _recipient) external;

    /**
     * @notice Notifies the Vault contract that a player lost a bet and sends USDT if player is the winner
     * @param _gameId Id of the game
     * @param _betAmount Amount of the bet in USDT
     * @param _totalAmount Amount of the bet multiplied by the odds
     * @param _houseEdgeAmount The house edge amount reducted from the total amount if the player wins
     * @param _isPlayerWinner Whether or not the player won or not
     * @param _receiveMontReward Whether or not the player should receive MONT rewards
     */
    function transferPlayerRewards(
        uint256 _gameId,
        uint256 _betAmount,
        uint256 _totalAmount,
        uint256 _houseEdgeAmount,
        bool _isPlayerWinner,
        bool _receiveMontReward
    ) external;

    /**
     * @notice Changes the minimum bet amount of USDT
     * @param _minimumBetAmount The new minimum bet amount
     */
    function setMinimumBetAmount(uint256 _minimumBetAmount) external;

    /**
     * @notice Returns the maximum bet amount a player can place
     */
    function getMaximumBetAmount() external view returns (uint256);

    /**
     * @notice Returns the minimum bet amount a player can place
     */
    function getMinimumBetAmount() external view returns (uint256);
}
