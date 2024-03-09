// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IVault {
    struct GameDetails {
        address player;
        address manager;
        address gameAddress;
    }

    /**
     * @notice Emitted when
     */
    event BurnerChanged(address indexed _from, address indexed _to);

    /**
     * @notice Emitted when
     */
    event Deposit(address indexed _spender, uint256 _amount);

    /**
     * @notice Emitted when
     */
    event GameFactoryChanged(address indexed _from, address indexed _to);

    /**
     * @notice Emitted when
     */
    event RewardManagerChanged(address indexed _from, address indexed _to);

    /**
     * @notice Emitted when
     */
    event GameFeeChanged(uint256 _from, uint256 _to);

    /**
     * @notice Emitted when
     */
    event GameCreated(uint256 _gameId, address _gameAddress, address _player);

    /**
     * @notice Emitted when
     */
    event MinimumBetAmountChanged(uint256 _from, uint256 _to);

    /**
     * @notice Emitted when
     */
    event Withdraw(address indexed _token, uint256 _amount, address indexed _recipient);

    /**
     * @notice Thrown when
     */
    error NotAuthorized();

    /**
     * @notice Thrown when
     */
    error FailedToSendEther();

    /**
     * @notice Thrown when
     */
    error InsufficientAmount();
}
