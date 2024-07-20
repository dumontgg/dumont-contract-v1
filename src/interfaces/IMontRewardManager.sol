// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// import {GameFactory} from "../GameFactory.sol";

/**
 * @title Reward Manager Interface
 * @notice Manages the distribution of MONT rewards to players based on game outcomes
 */
interface IMontRewardManager {
    /**
     * @notice Emitted when MONT rewards are assigned to a player
     * @param _player The address of the player getting the rewards
     * @param _reward The amount of MONT rewards assigned
     */
    event MontRewardAssigned(address indexed _player, uint256 _reward);

    /**
     * @notice Emitted when a player claims their MONT tokens
     * @param _player The address of the player calling the claim function
     * @param _amount The amount of MONT tokens transferred
     */
    event MontClaimed(address indexed _player, uint256 _amount);

    /**
     * @notice Emitted when the TWAP interval changes
     * @param _from The old TWAP interval in seconds
     * @param _to The new TWAP interval in seconds
     */
    event TwapIntervalChanged(uint32 _from, uint32 _to);

    /**
     * @notice Thrown when a caller is not authorized to perform an operation
     */
    error Unauthorized();

    /**
     * @notice Claims MONT tokens of the caller (player)
     * @return amount Amount of MONT tokens transferred to caller
     */
    function claim() external returns (uint256 amount);

    /**
     * @notice Transfers MONT rewards to the player based on game outcome
     * @param _betAmount Amount of the bet
     * @param _totalAmount Total amount of the bet multiplied by the odds
     * @param _houseEdgeAmount The house edge amount reducted from the total amount if the player wins
     * @param _player Address of the player
     * @param _isPlayerWinner Flag indicating whether the player won the bet
     * @return reward Amount of MONT rewards transferred to the player
     */
    function transferPlayerRewards(
        uint256 _betAmount,
        uint256 _totalAmount,
        uint256 _houseEdgeAmount,
        address _player,
        bool _isPlayerWinner
    ) external returns (uint256 reward);

    /**
     * @notice Changes the TWAP interval in seconds
     * @param _twapInterval The new TWAP interval in seconds
     */
    function setTwapInterval(uint32 _twapInterval) external;
}
