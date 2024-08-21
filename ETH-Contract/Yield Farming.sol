// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract YieldFarming {
    IERC20 public lpToken; // 流动性代币（LP Token）
    IERC20 public rewardToken; // 奖励代币（PEPE Token）
    uint public rewardRate = 100; // 每秒钟的奖励数量（假设为100 PEPE）

    struct Stake {
        uint amount; // 存入的LP Token数量
        uint rewardDebt; // 用户的未领取奖励
        uint lastUpdated; // 上次更新的时间戳
    }

    mapping(address => Stake) public stakes;

    uint public totalStaked; // 总存入的LP Token数量
    uint public accRewardPerShare; // 每个LP Token的累计奖励，放大1e12倍

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event ClaimReward(address indexed user, uint reward);

    constructor(IERC20 _lpToken, IERC20 _rewardToken) {
        lpToken = _lpToken;
        rewardToken = _rewardToken;
    }

    // 更新全局奖励信息
    function updatePool() internal {
        if (totalStaked == 0) {
            return;
        }

        uint timeElapsed = block.timestamp - stakes[msg.sender].lastUpdated;
        uint reward = timeElapsed * rewardRate;
        accRewardPerShare += reward * 1e12 / totalStaked;
        stakes[msg.sender].lastUpdated = block.timestamp;
    }

    // 存入LP Token进行流动性挖矿
    function deposit(uint _amount) external {
        Stake storage stake = stakes[msg.sender];
        updatePool();
        
        if (stake.amount > 0) {
            uint pendingReward = stake.amount * accRewardPerShare / 1e12 - stake.rewardDebt;
            if (pendingReward > 0) {
                rewardToken.transfer(msg.sender, pendingReward);
                emit ClaimReward(msg.sender, pendingReward);
            }
        }
        
        lpToken.transferFrom(msg.sender, address(this), _amount);
        stake.amount += _amount;
        stake.rewardDebt = stake.amount * accRewardPerShare / 1e12;
        totalStaked += _amount;

        emit Deposit(msg.sender, _amount);
    }

    // 提取LP Token和领取奖励
    function withdraw(uint _amount) external {
        Stake storage stake = stakes[msg.sender];
        require(stake.amount >= _amount, "提取金额超出存款金额");

        updatePool();
        
        uint pendingReward = stake.amount * accRewardPerShare / 1e12 - stake.rewardDebt;
        if (pendingReward > 0) {
            rewardToken.transfer(msg.sender, pendingReward);
            emit ClaimReward(msg.sender, pendingReward);
        }
        
        stake.amount -= _amount;
        stake.rewardDebt = stake.amount * accRewardPerShare / 1e12;
        lpToken.transfer(msg.sender, _amount);
        totalStaked -= _amount;

        emit Withdraw(msg.sender, _amount);
    }

    // 领取奖励
    function claimReward() external {
        Stake storage stake = stakes[msg.sender];
        updatePool();
        
        uint pendingReward = stake.amount * accRewardPerShare / 1e12 - stake.rewardDebt;
        if (pendingReward > 0) {
            rewardToken.transfer(msg.sender, pendingReward);
            emit ClaimReward(msg.sender, pendingReward);
        }

        stake.rewardDebt = stake.amount * accRewardPerShare / 1e12;
    }

    // 查询用户的存款信息
    function getStakeInfo(address _user) external view returns (uint stakedAmount, uint pendingReward) {
        Stake storage stake = stakes[_user];
        uint _accRewardPerShare = accRewardPerShare;
        
        if (totalStaked > 0) {
            uint timeElapsed = block.timestamp - stake.lastUpdated;
            uint reward = timeElapsed * rewardRate;
            _accRewardPerShare += reward * 1e12 / totalStaked;
        }

        stakedAmount = stake.amount;
        pendingReward = stake.amount * _accRewardPerShare / 1e12 - stake.rewardDebt;
    }
}
