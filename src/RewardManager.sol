// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Bool} from "./libraries/Bool.sol";
import {IMONT} from "./interfaces/IMONT.sol";
import {IQuoter} from "./interfaces/Uniswap/IQuoter.sol";
import {IRewardManager} from "./interfaces/IRewardManager.sol";

contract RewardManager is Ownable2Step, IRewardManager {
    using SafeERC20 for IMONT;

    IMONT public mont;
    IERC20 public usdt;
    address public vault;
    IQuoter public quoter;
    uint24 public poolFee;

    /**
     * @notice
     * @param _vault a
     * @param _mont a
     * @param _quoter a
     * @param _usdt a
     * @param _poolFee a
     */
    constructor(
        address _vault,
        IMONT _mont,
        IQuoter _quoter,
        IERC20 _usdt,
        uint24 _poolFee
    ) Ownable(msg.sender) {
        mont = _mont;
        usdt = _usdt;
        vault = _vault;
        quoter = _quoter;
        poolFee = _poolFee;
    }

    /**
     * @notice AA
     */
    modifier onlyVault() {
        if (msg.sender != vault) {
            revert Unauthorized();
        }

        _;
    }

    /**
     * @notice Changes the Vault address
     * @param _vault new Vault contract
     */
    function setVault(address _vault) external onlyOwner {
        emit VaultChanged(vault, _vault);

        vault = _vault;
    }

    /**
     * @notice Changes the Uniswap pool fee tier
     * @param _poolFee The new pool fee
     */
    function setPoolFee(uint24 _poolFee) external onlyOwner {
        emit PoolFeeChanged(poolFee, _poolFee);

        poolFee = _poolFee;
    }

    /**
     * @notice a
     * @param _betAmount a
     * @param _totalAmount a
     * @param _player a
     * @param _isPlayerWinner a
     * @return reward dd
     */
    function transferRewards(
        uint256 _betAmount,
        uint256 _totalAmount,
        address _player,
        bool _isPlayerWinner
    ) external onlyVault returns (uint256 reward) {
        uint256 houseFee = calculateHouseFee(
            _betAmount,
            _totalAmount,
            _isPlayerWinner
        );
        uint256 price = getMontPrice();

        // houseFee * 0.8 / price
        reward = ((houseFee * 8) / 10) / price;

        if (reward > _totalAmount) {
            reward = _totalAmount;
        }

        mont.safeTransfer(_player, reward);

        emit MontRewardTransferred(_player, reward);
    }

    /**
     * @notice a
     * @param _betAmount a
     * @param _totalAmount a
     * @param _isPlayerWinner a
     * @return houseFee dd
     */
    function calculateHouseFee(
        uint256 _betAmount,
        uint256 _totalAmount,
        bool _isPlayerWinner
    ) private pure returns (uint256 houseFee) {
        // TODO: use UD HERE
        houseFee = _totalAmount / 10;

        if (!_isPlayerWinner) {
            houseFee = _betAmount / 10;
        }
    }

    /**
     * @notice a
     * @return price dd
     */
    function getMontPrice() private returns (uint256 price) {
        price = quoter.quoteExactInputSingle(
            address(usdt),
            address(mont),
            poolFee,
            1e6,
            0
        );
    }
}
