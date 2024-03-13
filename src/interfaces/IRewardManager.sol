// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRewardManager {
    /**
     * @notice Emitted when
     * @param _from a
     * @param _to a
     */
    event VaultChanged(address indexed _from, address indexed _to);

    /**
     * @notice Emitted when
     * @param _from a
     * @param _to a
     */
    event PoolFeeChanged(uint24 indexed _from, uint24 indexed _to);

    /**
     * @notice Emitted when
     * @param _player a
     * @param _reward a
     */
    event MontRewardTransferred(address indexed _player, uint256 _reward);

    /**
     * @notice Thrown when
     */
    error Unauthorized();

    /**
     * @notice a
     * @param _betAmount a
     * @param _betOdds a
     * @param _player a
     * @param _isPlayerWinner a
     * @return reward dd
     */
    function transferRewards(
        uint256 _betAmount,
        uint256 _betOdds,
        address _player,
        bool _isPlayerWinner
    ) external returns (uint256 reward);
}
