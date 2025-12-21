// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol"
import "openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract Stake is Initializable, OwnableUpgradeable, UUPSUpgradeable, PausableUpgradeable,AccessControlUpgradeable {


    uint256 public startBlock;

    uint256 public endBlock;

    uint256 public metaNodePerBlock;


    byte32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public minDeposit = 2000*10**18;

    bool public  notDepositsEnabled ;

    bool public  notUnstakeEnabled ;

    bool public  notClaimRewardsEnabled;

    struct Pool {

        address stTokenAddress; // 质押代币地址

        uint256 poolWeight; // 权重

        uint256 lastRewardBlock; // 最后一次计算奖励的区块号

        uint256 stTokenAmount; // 总质押数量

        uint256 minDepositAmount; // 最小质押数量

        uint256 unstakeLockedBlocks; // 解质押锁定区块数
    }
    Pool[] public poolList;

    struct Request {

        uint256 amount; // 解质押数量

        uint256 requestBlock; // 解锁区块
    }

    
    struct User{

        uint256 stAmount; // 用户质押

        uint256 finishedMetaNode; // 已分配

        uint256 pendingMetaNode; // 待领取

        Request[] requests;

    }

    function initialize(
        IERC20 _stakeTokenAddress,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _metaNodePerBlock
    ) public initializer {

        require(_startBlock < _endBlock && _metaNodePerBlock > 0 , "invalid parameters");

        __Ownable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        __AccessControl_init();

        grantRole(ADMIN_ROLE, msg.sender);
        grantRole(UPGRADER_ROLE, msg.sender);
        setStakeTokenAddress(_stakeTokenAddress);
        startBlock = _startBlock;
        endBlock = _endBlock;
        metaNodePerBlock = _metaNodePerBlock;

    }

    function setStakeTokenAddress(IERC20 _stakeTokenAddress) public onlyRole(ADMIN_ROLE) {
        stakeTokenAddress = _stakeTokenAddress;
    }

    function deposit(uint256 _pid, uint256 _amount) public  {

        require(_amount >= minDeposit, "Deposit amount is less than minimum required");
    }

    function unstake(uint256 _pid, uint256 _amount ) public  {

    }

    function claimRewards(uint256 _pid) public  {

    }


    function addPool(
        address _stTokenAddress,
        uint256 _poolWeight,
        uint256 _lastRewardBlock,
        uint256 _stTokenAmount,
        uint256 minDepositAmount,
        uint256 _unstakeLockedBlocks
    ) public  {

        Pool memory pool = Pool({
            stTokenAddress: _stTokenAddress,
            poolWeight: _poolWeight,
            lastRewardBlock: _lastRewardBlock,
            stTokenAmount: _stTokenAmount,
            minDepositAmount: minDepositAmount,
            unstakeLockedBlocks: _unstakeLockedBlocks
        });

        poolList.push(pool);

    }

    function updatePool(uint256 _pid, bool _withUpdate) public  {

    }
}