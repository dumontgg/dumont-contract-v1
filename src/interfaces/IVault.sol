// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

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
     * @param _spender The address that initiated the deposit
     * @param _amount The amount deposited
     */
    event Deposit(address indexed _spender, uint256 _amount);

    /**
     * @notice Emitted when a new game is created
     * @param _gameId The ID of the newly created game
     * @param _gameAddress The address of the new game contract
     * @param _player The address of the player who created the game
     */
    event GameCreated(uint256 _gameId, address _gameAddress, address _player);

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
    event Withdraw(
        address indexed _token,
        uint256 _amount,
        address indexed _recipient
    );

    /**
     * @notice Thrown when the caller is not authorized to perform an action
     */
    error NotAuthorized();

    /**
     * @notice Thrown when an attempt to send ether fails
     */
    error FailedToSendEther();

    /**
     * @notice Thrown when the requested amount is not available
     */
    error InsufficientAmount();
}
