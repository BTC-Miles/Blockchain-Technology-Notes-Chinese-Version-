// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/* 该合约为锁定期每1ETH，每秒一个PEPE，锁定期20天过后可取回ETH，当质押过了40天，则额外获得200000个代币 */
contract PepeToken is ERC20, Ownable {
    struct Stake {
        uint256 amount; // 质押的ETH数量
        uint256 timestamp; // 质押的时间戳
    }

    mapping(address => Stake) public stakes;
    uint256 public rewardRatePerSecond = 1; // 每质押1 ETH 每秒奖励1个PEPE代币
    uint256 public lockPeriod = 20 days; // 锁定期20天
    uint256 public bonusPeriod = 40 days; // 奖励期40天
    uint256 public bonusAmount = 200000 * 10**18; // 额外奖励200000个PEPE代币

    constructor(uint256 initialSupply) ERC20("PepeToken", "PEPE") {
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

    // 用户质押ETH
    function stake() public payable {
        require(msg.value > 0, "质押的ETH数量必须大于0");

        // 如果用户已经有质押，先计算并分发未领取的奖励
        if (stakes[msg.sender].amount > 0) {
            uint256 reward = calculateReward(msg.sender);
            _mint(msg.sender, reward);
        }

        // 更新质押信息
        stakes[msg.sender].amount += msg.value;
        stakes[msg.sender].timestamp = block.timestamp;
    }

    // 用户取消质押并领取奖励
    function unstake() public {
        require(stakes[msg.sender].amount > 0, "没有质押的ETH");
        require(block.timestamp >= stakes[msg.sender].timestamp + lockPeriod, "质押尚未解锁");

        uint256 reward = calculateReward(msg.sender);
        uint256 stakedAmount = stakes[msg.sender].amount;

        // 检查用户是否满足奖励期要求
        if (block.timestamp >= stakes[msg.sender].timestamp + bonusPeriod) {
            reward += bonusAmount;
        }

        // 重置用户质押信息
        stakes[msg.sender].amount = 0;
        stakes[msg.sender].timestamp = 0;

        // 将质押的ETH返回给用户
        payable(msg.sender).transfer(stakedAmount);

        // 分发奖励
        _mint(msg.sender, reward);
    }

    // 计算用户的奖励
    function calculateReward(address staker) public view returns (uint256) {
        Stake memory stakeInfo = stakes[staker];
        uint256 stakingDuration = block.timestamp - stakeInfo.timestamp;
        // 奖励是质押ETH数量与质押时间的乘积，再乘以奖励速率
        return stakingDuration * rewardRatePerSecond * stakeInfo.amount / 1e18;
    }

    // 提取合约中的ETH，只有所有者可以调用
    function withdrawETH(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "合约中的ETH不足");
        payable(owner()).transfer(amount);
    }

    // 接收ETH
    receive() external payable {}
}

