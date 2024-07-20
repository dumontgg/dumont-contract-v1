// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UD60x18, ud} from "@prb/math/src/UD60x18.sol";

import {GameFactory} from "./GameFactory.sol";
import {IMONT} from "./interfaces/IMONT.sol";
import {IMontRewardManager} from "./interfaces/IMontRewardManager.sol";
import {OracleLibrary} from "./libraries/OracleLibrary.sol";
import {PoolAddress} from "./libraries/PoolAddress.sol";

/**
 * @title Reward Manager Contract
 * @notice Manages the distribution of MONT rewards to players based on game outcomes
 * @dev Only the Vault contract can call functions in this contract
 */
contract MontRewardManager is IMontRewardManager, Ownable {
    using SafeERC20 for IMONT;

    IMONT public immutable mont;
    IERC20 public immutable usdt;
    address public immutable vault;
    uint24 public immutable poolFee;
    address public immutable uniswapPool;
    GameFactory public immutable gameFactory;

    uint32 public twapInterval;
    mapping(address => uint256) public balances;

    /**
     * @notice Constructor to initialize contract state variables
     * @param _vault Address of the Vault contract
     * @param _mont Address of the MONT token contract
     * @param _usdt Address of the USDT token contract
     * @param _gameFactory Address of the GameFactory contract
     * @param _uniswapFactory Address of the UniswapV3Factory
     * @param _poolFee Uniswap pool fee tier
     * @param _twapInterval TWAP interval in seconds
     */
    constructor(
        address _vault,
        IMONT _mont,
        IERC20 _usdt,
        GameFactory _gameFactory,
        address _uniswapFactory,
        uint24 _poolFee,
        uint32 _twapInterval
    ) Ownable(msg.sender) {
        mont = _mont;
        usdt = _usdt;
        vault = _vault;
        gameFactory = _gameFactory;
        poolFee = _poolFee;
        twapInterval = _twapInterval;

        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(
            address(mont),
            address(usdt),
            _poolFee
        );

        uniswapPool = PoolAddress.computeAddress(_uniswapFactory, poolKey);
    }

    /**
     * @notice Changes the TWAP interval in seconds
     * @param _twapInterval The new TWAP interval in seconds
     */
    function setTwapInterval(uint32 _twapInterval) external onlyOwner {
        emit TwapIntervalChanged(twapInterval, _twapInterval);

        twapInterval = _twapInterval;
    }

    /**
     * @notice Claims MONT tokens of the caller (player)
     * @return amount Amount of MONT tokens transferred to caller
     */
    function claim() external returns (uint256 amount) {
        amount = balances[msg.sender];

        if (amount > 0) {
            balances[msg.sender] = 0;

            mont.safeTransfer(msg.sender, amount);
        }

        emit MontClaimed(msg.sender, amount);
    }

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
    ) external returns (uint256 reward) {
        if (msg.sender != vault) {
            revert Unauthorized();
        }

        // A number in like 100e6
        uint256 houseFee = calculateHouseFee(
            _betAmount,
            _houseEdgeAmount,
            _isPlayerWinner
        );
        UD60x18 inversePrice = getMontPrice();

        // (0.8 * HouseFee) / P
        /*
         * The numerator is multiplied to 1e30. Because:
         * 1. USDT has 6 decimals, we multiply it by 1e12 to make it 18 decimals
         * 2. To get better precision, we multiply it my 1e18 and after the calculations are over
         * we divide it by 1e18 again
         */
        reward =
            ud(((houseFee * 8) / 10) * 1e30).div(inversePrice).unwrap() /
            1e18;

        // Total Amount has 6 decimals, to make it 18 decimals, we multiply it by 1e12
        uint256 reward2 = _totalAmount * 1e12;

        // Check which one is less than the other, set that one as the reward amount
        if (reward > reward2) {
            reward = reward2;
        }

        (bool isReferrerSet, address referrer) = checkReferrer(_player);

        // Multiply the reward by 0.8 or 0.9 based on referral status of the player
        if (!isReferrerSet) {
            reward = (reward * 8) / 10;
        } else if (isReferrerSet) {
            reward = (reward * 9) / 10;

            balances[referrer] += reward / 10;

            emit MontRewardAssigned(referrer, reward / 10);
        }

        balances[_player] += reward;

        emit MontRewardAssigned(_player, reward);
    }

    /**
     * @notice Calculates the house fee based on game outcome
     * @param _betAmount Amount of the bet
     * @param _houseEdgeAmount The house edge amount reducted from the total amount if the player wins
     * @param _isPlayerWinner Flag indicating whether the player won the bet
     * @return houseFee Calculated house fee
     */
    function calculateHouseFee(
        uint256 _betAmount,
        uint256 _houseEdgeAmount,
        bool _isPlayerWinner
    ) private pure returns (uint256 houseFee) {
        houseFee = _houseEdgeAmount;

        if (!_isPlayerWinner) {
            houseFee = _betAmount / 10;
        }
    }

    /**
     * @notice Retrieves the current price of MONT token from Uniswap
     * @return inversePrice Current price of MONT token
     */
    function getMontPrice() private view returns (UD60x18 inversePrice) {
        int24 twapTick = OracleLibrary.consult(uniswapPool, twapInterval);

        uint256 amountQuote = OracleLibrary.getQuoteAtTick(
            twapTick,
            1e6,
            address(usdt),
            address(mont)
        );

        inversePrice = ud(1e18).div(ud(amountQuote)).mul(ud(1e18));
    }

    /**
     * @notice Checks if the player has used an invite link
     * @param _referee The player of the game getting the rewards
     * @return isReferrerSet If the referrer is set for the referee (player)
     * @return referrer Address of the referrer of the referee (player)
     */
    function checkReferrer(
        address _referee
    ) private view returns (bool isReferrerSet, address referrer) {
        referrer = gameFactory.referrals(_referee);

        if (referrer != address(0)) {
            isReferrerSet = true;
        }
    }
}
