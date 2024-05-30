// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {console2} from "forge-std/console2.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {GameFactory} from "./GameFactory.sol";
import {IMONT} from "./interfaces/IMONT.sol";
import {IQuoter} from "./interfaces/Uniswap/IQuoter.sol";
import {IMontRewardManager} from "./interfaces/IMontRewardManager.sol";

// todo: why ownable?
/**
 * @title Reward Manager Contract
 * @notice Manages the distribution of MONT rewards to players based on game outcomes
 * @dev Only the Vault contract can call functions in this contract
 */
contract MontRewardManager is IMontRewardManager {
    using SafeERC20 for IMONT;

    IMONT public immutable mont;
    IERC20 public immutable usdt;
    address public immutable vault;
    IQuoter public immutable quoter;
    uint24 public immutable poolFee;
    GameFactory public immutable gameFactory;

    mapping(address => uint256) public balances;

    /**
     * @notice Modifier to restrict access to only the Vault contract
     */
    modifier onlyVault() {
        if (msg.sender != vault) {
            revert Unauthorized();
        }

        _;
    }

    /**
     * @notice Constructor to initialize contract state variables
     * @param _vault Address of the Vault contract
     * @param _mont Address of the MONT token contract
     * @param _usdt Address of the USDT token contract
     * @param _gameFactory Address of the GameFactory contract
     * @param _quoter Address of the Uniswap quoter contract
     * @param _poolFee Uniswap pool fee tier
     */
    constructor(address _vault, IMONT _mont, IERC20 _usdt, GameFactory _gameFactory, IQuoter _quoter, uint24 _poolFee) {
        mont = _mont;
        usdt = _usdt;
        vault = _vault;
        gameFactory = _gameFactory;
        quoter = _quoter;
        poolFee = _poolFee;
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
     * @param _player Address of the player
     * @param _isPlayerWinner Flag indicating whether the player won the bet
     * @return reward Amount of MONT rewards transferred to the player
     */
    function transferPlayerRewards(uint256 _betAmount, uint256 _totalAmount, address _player, bool _isPlayerWinner)
        external
        onlyVault
        returns (uint256 reward)
    {
        uint256 houseFee = calculateHouseFee(_betAmount, _totalAmount, _isPlayerWinner);
        uint256 price = getMontPrice();

        reward = ((houseFee * 8) / 10) / price;

        if (reward > _totalAmount) {
            reward = _totalAmount;
        }

        console2.log("%s", reward);

        (bool isReferrerSet, address referrer) = checkReferrer(_player);

        if (!isReferrerSet) {
            reward = (_totalAmount * 8) / 10;
        } else if (isReferrerSet) {
            balances[referrer] += reward / 10;
        }

        balances[_player] += reward;

        emit MontRewardAssigned(_player, reward);
    }

    /**
     * @notice Calculates the house fee based on game outcome
     * @param _betAmount Amount of the bet
     * @param _totalAmount Total amount of the bet multiplied by the odds
     * @param _isPlayerWinner Flag indicating whether the player won the bet
     * @return houseFee Calculated house fee
     */
    function calculateHouseFee(uint256 _betAmount, uint256 _totalAmount, bool _isPlayerWinner)
        private
        pure
        returns (uint256 houseFee)
    {
        houseFee = _totalAmount / 10;

        if (!_isPlayerWinner) {
            houseFee = _betAmount / 10;
        }
    }

    /**
     * @notice Retrieves the current price of MONT token from Uniswap
     * @return price Current price of MONT token
     */
    function getMontPrice() private pure returns (uint256 price) {
        // todo:
        // price = quoter.quoteExactInputSingle(address(usdt), address(mont), poolFee, 1e6, 0);
        price = 100000 * 10e18;
    }

    /**
     * @notice Checks if the player has used an invite link
     * @param _referee The player of the game getting the rewards
     * @return isReferrerSet If the referrer is set for the referee (player)
     * @return referrer Address of the referrer of the referee (player)
     */
    function checkReferrer(address _referee) private view returns (bool isReferrerSet, address referrer) {
        referrer = gameFactory.referrals(_referee);

        if (referrer != address(0)) {
            isReferrerSet = true;
        }
    }
}
