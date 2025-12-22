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

    uint256 public totalPoolWeight;


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

    // pool id => user address => user info
    mapping(address => mapping(uint256 => UserInfo)) public userInfo;

    event AddPool(address indexed setStakeTokenAddress, uint256 indexed poolWeight,uint256 lastRewardBlock, uint256 stTokenAmount, uint256 minDepositAmount, uint256 unstakeLockedBlocks);

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

        require(block.number >= startBlock, "Stake period has not started");

        require(_pid != 0, "deposit not support ETH");

        Pool storage pool_ = poolList[_pid];

        require(_amount >= pool_.minDepositAmount, "Deposit amount is less than minimum required");

        if (_amount > 0) { 
            IERC20(pool_.stTokenAddress).transferFrom(msg.sender, address(this), _amount);
        }
        _deposit(_pid, _amount);
    }

    function _deposit(uint256 _pid, uint256 _amount) internal { 
        Pool storage pool_ = poolList[_pid];
        UserInfo storage user_ = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user_.stAmount > 0) {
            uint256 pending = user_.stAmount * pool_.accStTokenPerShare / (1 ether)) - user_.finishedMetaNode;
            if (pending > 0) {
                user_.pendingMetaNode += pending;
            }
        }
        if (_amount > 0) {
            user_.stAmount += _amount;
            user.requests.push(Request({
                amount: _amount,
                requestBlock: block.number + pool_.unstakeLockedBlocks
            }));
        }
        

        user_.finishedMetaNode = user_.stAmount * pool_.accStTokenPerShare / (1 ether));
    }


    function unstake(uint256 _pid, uint256 _amount ) public  {
        pool memory pool_ = pools[_pid];
        user memory user_ = users[msg.sender][_pid];
        require(user_.stAmount >= _amount, "Not enough staked");
        updatePool(_pid);
        uint256 pending = user_.stAmount * pool_.accStTokenPerShare / (1 ether)) - user_.finishedMetaNode;
        if (pending > 0) {
            user_.pendingMetaNode += pending;
        }

        if (_amount > 0) {
            user_.stAmount -= _amount;
            pool_.stTokenAmount -= _amount;
            user.requests.push(Request({
                amount: _amount,
                requestBlock: block.number + pool_.unstakeLockedBlocks
            }));
        }

        user.finishedMetaNode = user_.stAmount * pool_.accStTokenPerShare / (1 ether)

    }

    function withdraw(uint256 _pid) public  {
        Pool storage pool_ = poolList[_pid];
        UserInfo storage user_ = userInfo[_pid][msg.sender];

        uint256 pendingWithdraw_ ;
        uint256 popNum_ ;
        for (uint256 i = 0; i < user_.requests.length; i++) {
            Request storage request_ = user_.requests[i];
            if (request_.requestBlock > block.number) {
                break;
            }
            pendingWithdraw_ += request_.amount;
            popNum_ ++;
        }

        for (uint256 i = 0; i < user_.requests.length - popNum_; i++) {
            user_.requests[i] = user_.requests[i + popNum_];
        }
        for (uint256 i = 0; i < popNum_; i++) {
            user_.requests.pop();
        }

        if (pendingWithdraw_ > 0) {
            if (pool_.stTokenAddress == address(0x0)) {
                payable(msg.sender).transfer(pendingWithdraw_);
            } else {
                IERC20(pool_.stTokenAddress).safeTransfer(msg.sender, pendingWithdraw_);
            }

        }

    }

    function claimRewards(uint256 _pid) public  {

        PoolInfo storage pool_ = poolInfo[_pid];
        UserInfo storage user_ = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = user_.stAmount * pool_.accStTokenPerShare / (1 ether)) - user_.finishedMetaNode + user_.pendingMetaNode;
        if (pending > 0) {
            user_.pendingMetaNode = 0;
            IERC20(metaNodeTokenAddress).safeTransfer(msg.sender, pending);
        }

        user_.finishedMetaNode = user_.stAmount * pool_.accStTokenPerShare / (1 ether));

    }


    function addPool(
        address _stTokenAddress,
        uint256 _poolWeight,
        uint256 _stTokenAmount,
        uint256 _minDepositAmount,
        uint256 _unstakeLockedBlocks,
        bool _withUpdate
    ) public  {
        if (poolList.length == 0) {
            require(_stTokenAddress ==address(0x0), "First pool must be for native token");
        } else {
            require(_stTokenAddress != address(0x0), "Pool must be for native token");
        }
        
        require(_poolWeight > 0, "Pool weight must be greater than zero");
        require(_stTokenAmount >0 , "Staked token amount must be greater than zero");
        require(_unstakeLockedBlocks > 0, "Unstake locked blocks must be greater than zero");
        if (_withUpdate) {
            massUpdatePool();
        }
        uint256 _lastRewardBlock  = block.number > startBlock ? block.number : startBlock;

        totalPoolWeight += _poolWeight;
        Pool memory pool = Pool({
            stTokenAddress: _stTokenAddress,
            poolWeight: _poolWeight,
            lastRewardBlock: _lastRewardBlock,
            stTokenAmount: _stTokenAmount,
            minDepositAmount: minDepositAmount,
            unstakeLockedBlocks: _unstakeLockedBlocks
        });

        poolList.push(pool);

        emit AddPool(_pid, _stTokenAddress, _poolWeight, _stTokenAmount, _unstakeLockedBlocks);

    }

    function updatePool(uint256 _pid, 
        uint256 _minDepositAmount,
        uint256 _unstakeLockedBlocks
    ) public  {
        Pool storage pool_ = poolList[_pid];

        pool_.minDepositAmount = _minDepositAmount;
        pool_.unstakeLockedBlocks = _unstakeLockedBlocks;

    }

    function massUpdatePool() public  {
        uint256 length = poolList.length;
        for (uint i = 0 ; i < length; i++) {
            updatePool(i);
        }
    }

    function updatePool(uint256 _pid) public  {
        PoolInfo storage pool_ = poolList[_pid];

        if (pool_.lastRewardBlock >= block.number) {
            return;
        }
        uint256 totalMetaNode  = getMultiplier(pool_.lastRewardBlock, block.number);

        totalMetaNode =  totalMetaNode * pool_.poolWeight / totalPoolWeight;

        uint256 stSupply = pool_.stTokenAmount;
        if (stSupply > 0) {
            pool_.accStTokenPerShare = pool_.accStTokenPerShare + totalMetaNode * (1 ether)) / stSupply;
        }

        pool_.lastRewardBlock = block.number;

    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256 multiplier) {
        require(_to > _from, "invalid block);
        if (_form < startBlock ) {
            _form = startBlock;
        }
        if (_to > endBlock) {
            _to = endBlock;
        }

        bool success;

        (success, multiplier) =  (_to - _from) * metaNodePerBlock;
        require(success, "overflow");
    }



}