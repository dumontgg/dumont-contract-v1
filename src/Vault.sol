// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import {IDMT} from "./interfaces/IDMT.sol";
import {IGame} from "./interfaces/IGame.sol";
import {IVault} from "./interfaces/IVault.sol";
import {IBurner} from "./interfaces/IBurner.sol";
import {IGameFactory} from "./interfaces/IGameFactory.sol";

/**
 * @notice That vault contract that stores DAI and manages other contracts
 * @author X team
 * @notice The vault is used to create games, and all deposits and withdrawals happen
 */
contract Vault is IVault, Ownable2Step {
    uint256 public minimumBetAmount = 1e18;
    uint256 public gameId = 0;
    uint256 public gameFeeInWei;
    mapping(uint256 => GameUsers) public games;

    IDMT public dmt;
    IERC20 public usdt;
    IBurner public burner;
    IGameFactory public gameFactory;

    event BurnerChanged(address indexed _from, address indexed _to);
    event Deposit(address indexed _spender, uint256 _amount);
    event GameFactoryChanged(address indexed _from, address indexed _to);
    event GameFeeChanged(uint256 _from, uint256 _to);
    event GameCreated(uint256 _gameId, address _gameAddress, address _player);
    event MinimumBetAmountChanged(uint256 _from, uint256 _to);
    event Withdraw(address indexed _token, uint256 _amount, address indexed _recipient);

    error NotAuthorized();
    error FailedToSendEther();
    error InsufficientAmount();

    /**
     * @notice Sets contract addresses and gameFee
     * @param _dmt Address of the Dumont token
     * @param _usdt The address of the USDT token
     * @param _burner Address of the burner token used to sell DAI and burn DMN tokens
     * @param _gameFactory Address of the GameFactory contract
     * @param _gameFeeInWei Sets the fee to create games
     */
    constructor(IDMT _dmt, IERC20 _usdt, IBurner _burner, IGameFactory _gameFactory, uint256 _gameFeeInWei) {
        dmt = _dmt;
        usdt = _usdt;
        burner = _burner;
        gameFactory = _gameFactory;
        gameFeeInWei = _gameFeeInWei;
    }

    modifier onlyPlayer(uint256 _gameId) {
        if (games[_gameId].player == msg.sender) {
            revert NotAuthorized();
        }

        _;
    }

    /**
     * @notice Changes the minimum bet amount of DAI
     * @param _minimumBetAmount The new minimum bet amount
     */
    function setMinimumBetAmount(uint256 _minimumBetAmount) external onlyOwner {
        emit MinimumBetAmountChanged(minimumBetAmount, _minimumBetAmount);

        minimumBetAmount = _minimumBetAmount;
    }

    /**
     * @notice Returns the maximum bet amount a user can place
     */
    function getMaximumBetAmount() public view returns (uint256) {
        uint256 daiAmount = usdt.balanceOf(address(this));

        // TODO: Do we need to multiply by 100 and then divide or it's good now?
        return (daiAmount / 100) * 5;
    }

    /**
     * @notice Changes the address of Burner contract
     * @param _burner The new address of the Burner contract
     */
    function setBurner(IBurner _burner) external onlyOwner {
        emit BurnerChanged(address(burner), address(_burner));

        burner = _burner;
    }

    /**
     * @notice Changes the address of GameFactory contract
     * @param _gameFactory The new address of the GameFactory contract
     */
    function setGameFactory(IGameFactory _gameFactory) external onlyOwner {
        emit GameFactoryChanged(address(gameFactory), address(_gameFactory));

        gameFactory = _gameFactory;
    }

    /**
     * @notice Changes the fee required to make a new game
     * @param _gameFeeInWei The new amount of ether needed to create a game
     */
    function setGameFee(uint256 _gameFeeInWei) external onlyOwner {
        emit GameFeeChanged(gameFeeInWei, _gameFeeInWei);

        gameFeeInWei = _gameFeeInWei;
    }

    /**
     * @notice Deposits DAI into the contract
     * @param _amount The amount of DAI to deposit
     * @dev Should be called by the admins of the protocol
     */
    function depositDai(uint256 _amount) external {
        usdt.transferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Withdraws an amount of a specific token, usually DAI or DMN
     * @param _token The ERC20 token to withdraw
     * @param _amount The amount of token to withdraw
     * @param _recipient The destination address that will receive the tokens
     * @dev This can only be called by the owner of the contract
     */
    function withdrawToken(address _token, uint256 _amount, address _recipient) external onlyOwner {
        IERC20(_token).transfer(_recipient, _amount);

        emit Withdraw(_token, _amount, _recipient);
    }

    /**
     * @notice Withdraws ETH from the contract and transfers it to the recipient
     * @param _recipient The destination address that will receive ETH
     * @dev ETH gets stored when the createGame function is called
     * and this function can only be called by the owner
     */
    function withdrawETH(address _recipient) external onlyOwner {
        uint256 balance = address(this).balance;

        (bool success,) = _recipient.call{value: balance}("");

        if (!success) {
            revert FailedToSendEther();
        }
    }

    /**
     * @notice Creates a new game using the GameFactory contract and stores the related data
     * @dev The caller need to pay at least gameFeeInWei amount to create a game
     */
    function createGame() external payable {
        if (msg.value < gameFeeInWei) {
            revert InsufficientAmount();
        }

        (address gameAddress, address server) = gameFactory.createGame(msg.sender, gameId);

        games[gameId] = GameUsers({gameAddress: gameAddress, player: msg.sender, server: server});

        emit GameCreated(gameId, gameAddress, msg.sender);

        unchecked {
            ++gameId;
        }
    }

    // function calculateBurnAmount() internal {}
    //
    // function gameLost() internal {}
}
