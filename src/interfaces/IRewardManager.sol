// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @title Reward Manager Interface
 * @notice Manages the distribution of MONT rewards to players based on game outcomes
 */
interface IRewardManager {
    /**
     * @notice Emitted when the Vault contract address is changed
     * @param _from The old Vault contract address
     * @param _to The new Vault contract address
     */
    event VaultChanged(address indexed _from, address indexed _to);

    /**
     * @notice Emitted when the Uniswap pool fee tier is changed
     * @param _from The old pool fee tier
     * @param _to The new pool fee tier
     */
    event PoolFeeChanged(uint24 indexed _from, uint24 indexed _to);

    /**
     * @notice Emitted when MONT rewards are transferred to a player
     * @param _player The address of the player receiving the rewards
     * @param _reward The amount of MONT rewards transferred
     */
    event MontRewardTransferred(address indexed _player, uint256 _reward);

    /**
     * @notice Thrown when a caller is not authorized to perform an operation
     */
    error Unauthorized();

    /**
     * @notice Changes the address of the Vault contract
     * @param _vault New Vault contract address
     */
    function setVault(address _vault) external;

    /**
     * @notice Changes the Uniswap pool fee tier
     * @param _poolFee New Uniswap pool fee
     */
    function setPoolFee(uint24 _poolFee) external;

    /**
     * @notice Transfers MONT rewards to the player based on game outcome
     * @param _betAmount Amount of the bet
     * @param _totalAmount Total amount of the bet multiplied by the odds
     * @param _player Address of the player
     * @param _isPlayerWinner Flag indicating whether the player won the bet
     * @return reward Amount of MONT rewards transferred to the player
     */
    function transferRewards(uint256 _betAmount, uint256 _totalAmount, address _player, bool _isPlayerWinner)
        external
        returns (uint256 reward);
}
