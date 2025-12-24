// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract Stake is Initializable, OwnableUpgradeable, UUPSUpgradeable, PausableUpgradeable,AccessControlUpgradeable {

    using SafeERC20 for IERC20;

    uint256 public startBlock;

    uint256 public endBlock;

    uint256 public metaNodePerBlock;

    uint256 public totalPoolWeight;


    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public minDeposit = 2000*10**18;

    bool public  depositsEnabled ;

    bool public  unstakeEnabled ;

    bool public  claimRewardsEnabled;

    bool public withdrawEnabled;

    IERC20 public stakeTokenAddress;

    uint256 public constant ETH_PID = 0;

    struct Pool {

        address stTokenAddress; // 质押代币地址

        uint256 poolWeight; // 权重

        uint256 lastRewardBlock; // 最后一次计算奖励的区块号

        uint256 stTokenAmount; // 总质押数量

        uint256 minDepositAmount; // 最小质押数量

        uint256 unstakeLockedBlocks; // 解质押锁定区块数

        uint256 accStTokenPerShare;
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
    mapping(uint256 => mapping(address => User)) public userInfo;

    //
    modifier checkPid(uint256  _pid) {
        require(_pid < poolList.length, "Invalid pool id");
        _;
    }
    event AddPool(address indexed setStakeTokenAddress, 
        uint256 indexed poolWeight,
        uint256 lastRewardBlock, 
        uint256 minDepositAmount, 
        uint256 unstakeLockedBlocks);

    function initialize(
        IERC20 _stakeTokenAddress,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _metaNodePerBlock
    ) public initializer {

        require(_startBlock < _endBlock && _metaNodePerBlock > 0 , "invalid parameters");

        // __Ownable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // 赋予自己最高管理员权限
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        setStakeTokenAddress(_stakeTokenAddress);
        startBlock = _startBlock;
        endBlock = _endBlock;
        metaNodePerBlock = _metaNodePerBlock;

        depositsEnabled = true;
        unstakeEnabled = true;
        claimRewardsEnabled = true;
        withdrawEnabled = true;
    }

    function setDepositsEnabled(bool _enabled) public onlyRole(ADMIN_ROLE) {
        depositsEnabled = _enabled;
    }
     function setUnstakeEnabled(bool _enabled) public onlyRole(ADMIN_ROLE) {
        unstakeEnabled = _enabled;
    }
     function setClaimRewardsEnabled(bool _enabled) public onlyRole(ADMIN_ROLE) {
        claimRewardsEnabled = _enabled;
    }

    function setStakeTokenAddress(IERC20 _stakeTokenAddress) public onlyRole(ADMIN_ROLE) {
        stakeTokenAddress = _stakeTokenAddress;
    }

    function depositETH() public payable {
        require(depositsEnabled , "Deposits are disabled");
        Pool storage pool_ = poolList[0];
        require(pool_.stTokenAddress == address(0x0), "ETH deposit not supported");
        uint256 _amount =  msg.value;
        require(_amount >= pool_.minDepositAmount, "Deposit amount is less than minimum required");
        _deposit(ETH_PID, _amount);
    }


    function deposit(uint256 _pid, uint256 _amount) public  checkPid(_pid) {
        require(depositsEnabled , "Deposits are disabled");

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
        User storage user_ = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user_.stAmount > 0) {
            uint256 pending = user_.stAmount * pool_.accStTokenPerShare / (1 ether) - user_.finishedMetaNode;
            if (pending > 0) {
                user_.pendingMetaNode += pending;
            }
        }
        if (_amount > 0) {
            user_.stAmount += _amount;
            user_.requests.push(Request({
                amount: _amount,
                requestBlock: block.number + pool_.unstakeLockedBlocks
            }));
        }
        

        user_.finishedMetaNode = user_.stAmount * pool_.accStTokenPerShare / (1 ether);
    }


    function unstake(uint256 _pid, uint256 _amount ) public checkPid(_pid) {
        require(unstakeEnabled, "Unstaking is disabled");
        Pool memory pool_ = poolList[_pid];
        User storage user_ = userInfo[_pid][msg.sender];
        require(user_.stAmount >= _amount, "Not enough staked");
        updatePool(_pid);
        uint256 pending = user_.stAmount * pool_.accStTokenPerShare / (1 ether) - user_.finishedMetaNode;
        if (pending > 0) {
            user_.pendingMetaNode += pending;
        }

        if (_amount > 0) {
            user_.stAmount -= _amount;
            pool_.stTokenAmount -= _amount;
            user_.requests.push(Request({
                amount: _amount,
                requestBlock: block.number + pool_.unstakeLockedBlocks
            }));
        }

        user_.finishedMetaNode = user_.stAmount * pool_.accStTokenPerShare / (1 ether);

    }

    function withdraw(uint256 _pid) public checkPid(_pid) {

        require(withdrawEnabled, "Withdraw is disabled");
        Pool storage pool_ = poolList[_pid];
        User storage user_ = userInfo[_pid][msg.sender];

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
                // payable(msg.sender).transfer(pendingWithdraw_);
                _safeETHTransfer(msg.sender, pendingWithdraw_);
            } else {
                IERC20(pool_.stTokenAddress).transfer(msg.sender, pendingWithdraw_);
            }

        }

    }

    function claimRewards(uint256 _pid) public checkPid(_pid) {
        require(claimRewardsEnabled, "Claiming rewards is disabled");
        Pool storage pool_ = poolList[_pid];
        User storage user_ = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = user_.stAmount * pool_.accStTokenPerShare / (1 ether) - user_.finishedMetaNode + user_.pendingMetaNode;
        if (pending > 0) {
            user_.pendingMetaNode = 0;
            IERC20(stakeTokenAddress).safeTransfer(msg.sender, pending);
        }

        user_.finishedMetaNode = user_.stAmount * pool_.accStTokenPerShare / (1 ether);

    }


    function addPool(
        address _stTokenAddress,
        uint256 _poolWeight,
        uint256 _minDepositAmount,
        uint256 _unstakeLockedBlocks,
        bool _withUpdate
    ) public  onlyRole(ADMIN_ROLE) {
        if (poolList.length == 0) {
            require(_stTokenAddress ==address(0x0), "First pool must be for native token");
        } else {
            require(_stTokenAddress != address(0x0), "Pool must be for native token");
        }
        
        require(_poolWeight > 0, "Pool weight must be greater than zero");
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
            stTokenAmount: 0,
            minDepositAmount: _minDepositAmount,
            unstakeLockedBlocks: _unstakeLockedBlocks,
            accStTokenPerShare: 0
        });

        poolList.push(pool);

        emit AddPool(_stTokenAddress, _poolWeight, _lastRewardBlock , _minDepositAmount, _unstakeLockedBlocks);

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

    function updatePool(uint256 _pid) public  onlyRole(ADMIN_ROLE) checkPid(_pid) {
        Pool storage pool_ = poolList[_pid];

        if (pool_.lastRewardBlock >= block.number) {
            return;
        }
        uint256 totalMetaNode  = getMultiplier(pool_.lastRewardBlock, block.number);

        totalMetaNode =  totalMetaNode * pool_.poolWeight / totalPoolWeight;

        uint256 stSupply = pool_.stTokenAmount;
        if (stSupply > 0) {
            pool_.accStTokenPerShare = pool_.accStTokenPerShare + totalMetaNode * (1 ether) / stSupply;
        }

        pool_.lastRewardBlock = block.number;

    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256 multiplier) {
        require(_to > _from, "invalid block");
        if (_from < startBlock ) {
            _from = startBlock;
        }
        if (_to > endBlock) {
            _to = endBlock;
        }

        multiplier =  (_to - _from) * metaNodePerBlock;
    }

    function _safeETHTransfer(address _to, uint256 _amount) internal {
        (bool success, bytes memory data) = address(_to).call{value: _amount}("");
        require(success, "ETH transfer call failed");
        if (data.length > 0) {
            require(abi.decode(data,(bool)), "ETH transfer operation did not succeed");

        }
    }

    function _authorizeUpgrade( address newImplementation) internal override onlyRole(UPGRADER_ROLE) {

    }

}