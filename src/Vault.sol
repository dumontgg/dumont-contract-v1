// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IGame} from "./interfaces/IGame.sol";
import {IVault} from "./interfaces/IVault.sol";
import {Ownable} from "./libraries/Ownable.sol";
import {IBurner} from "./interfaces/IBurner.sol";
import {IDMN} from "./interfaces/ERC20/IDMN.sol";
import {IERC20} from "./interfaces/ERC20/IERC20.sol";
import {IGameFactory} from "./interfaces/IGameFactory.sol";

/**
 * @notice That vault contract that stores DAI and manages other contracts
 * @author X team
 * @notice The vault is used to create games, and all deposits and withdrawals happen
 */
contract Vault is IVault, Ownable {
    struct GameStruct {
        address player;
        address gameAddress;
    }

    IDMN public DMN;
    IERC20 public DAI;
    IBurner public Burner;
    IGameFactory public GameFactory;

    uint256 public gameFeeInWei;
    uint256 public gameId = 0;
    mapping(uint256 => GameStruct) public games;

    event Deposit(address indexed _spender, uint256 _amount);
    event Withdraw(address indexed _token, uint256 _amount, address indexed _recipient);
    event BurnerChanged(address indexed _from, address indexed _to);
    event GameFactoryChanged(address indexed _from, address indexed _to);
    event GameFeeChanged(uint256 _from, uint256 _to);
    event GameCreated(uint256 _gameId, address _gameAddress, address _player);

    error FailedToSendEther();
    error InsufficientAmount();

    /**
     * @notice Sets contract addresses and gameFee
     * @param _dmn Address of the Dumont token
     * @param _dai Address of the DAI token
     * @param _burner Address of the burner token used to sell DAI and burn DMN tokens
     * @param _gameFactory Address of the GameFactory contract
     * @param _gameFeeInWei Sets the fee to create games
     */
    constructor(IDMN _dmn, IERC20 _dai, IBurner _burner, IGameFactory _gameFactory, uint256 _gameFeeInWei)
        Ownable(msg.sender)
    {
        DMN = _dmn;
        DAI = _dai;
        Burner = _burner;
        GameFactory = _gameFactory;
        gameFeeInWei = _gameFeeInWei;
    }

    /**
     * @notice Changes the address of Burner contract
     * @param _burner The new address of the Burner contract
     */
    function setBurner(IBurner _burner) external onlyOwner {
        emit BurnerChanged(address(Burner), address(_burner));

        Burner = _burner;
    }

    /**
     * @notice Changes the address of GameFactory contract
     * @param _gameFactory The new address of the GameFactory contract
     */
    function setGameFactory(IGameFactory _gameFactory) external onlyOwner {
        emit GameFactoryChanged(address(GameFactory), address(_gameFactory));

        GameFactory = _gameFactory;
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
        DAI.transferFrom(msg.sender, address(this), _amount);

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

        address gameAddress = GameFactory.createGame(msg.sender, gameId);

        games[gameId] = GameStruct({gameAddress: gameAddress, player: msg.sender});

        emit GameCreated(gameId, gameAddress, msg.sender);

        unchecked {
            ++gameId;
        }
    }

    // function calculateBurnAmount() internal {}
    //
    // function gameLost() internal {}
}
