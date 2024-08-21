// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Stake) public stakes;
    uint256 public rewardRatePerSecond = 1; // 每秒奖励1个代币

    constructor(uint256 initialSupply) ERC20("MyToken", "MTK") {
        _mint(msg.sender, initialSupply);
    }

    // 铸造新的代币，只有合约所有者可以调用
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // 销毁代币
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    // 质押代币
    function stake(uint256 amount) public {
        require(amount > 0, "质押金额必须大于0");
        require(balanceOf(msg.sender) >= amount, "余额不足");

        // 如果用户已经有质押，先计算并分发未领取的奖励
        if (stakes[msg.sender].amount > 0) {
            uint256 reward = calculateReward(msg.sender);
            _mint(msg.sender, reward);
        }

        // 将代币从用户账户转移到合约，并更新质押信息
        _transfer(msg.sender, address(this), amount);
        stakes[msg.sender].amount += amount;
        stakes[msg.sender].timestamp = block.timestamp;
    }

    // 取消质押并领取奖励
    function unstake() public {
        require(stakes[msg.sender].amount > 0, "没有质押的代币");

        uint256 reward = calculateReward(msg.sender);
        uint256 stakedAmount = stakes[msg.sender].amount;

        // 重置用户质押信息
        stakes[msg.sender].amount = 0;
        stakes[msg.sender].timestamp = 0;

        // 将质押的代币返回给用户
        _transfer(address(this), msg.sender, stakedAmount);

        // 分发奖励
        _mint(msg.sender, reward);
    }

    // 计算用户的奖励
    function calculateReward(address staker) public view returns (uint256) {
        Stake memory stakeInfo = stakes[staker];
        uint256 stakingDuration = block.timestamp - stakeInfo.timestamp;
        return stakingDuration * rewardRatePerSecond * stakeInfo.amount / 1e18;
    }
}

