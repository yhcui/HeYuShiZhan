const { expect } = require("chai");
const { ethers, deployments, getNamedAccounts } = require("hardhat");
const { mine } = require("@nomicfoundation/hardhat-network-helpers");

describe("Stake Contract", function () {
    let stake, stakeToken, deployer, user1;
    let STK_AMOUNT = ethers.parseEther("10000");

    beforeEach(async () => {
        // 重新部署所有带有标签的合约
        await deployments.fixture(["staketoken", "stake"]);
        
        const namedAccounts = await getNamedAccounts();
        deployer = namedAccounts.deployer;
        const signers = await ethers.getSigners();
        user1 = signers[1];

        // 获取合约实例
        const StakeDeployment = await deployments.get("Stake");
        stake = await ethers.getContractAt("Stake", StakeDeployment.address);
        
        const TokenDeployment = await deployments.get("StakeToken");
        stakeToken = await ethers.getContractAt("StakeToken", TokenDeployment.address);

        // 给 user1 转一些代币用于质押测试
        const deployerSigner = await ethers.getSigner(deployer);
        await stakeToken.connect(deployerSigner).transfer(user1.address, STK_AMOUNT);
    });

    it("应该成功添加一个 ERC20 质押池", async () => {
        // 第0个池子通常是 ETH (见合约代码 addPool 逻辑)
        await stake.addPool(ethers.ZeroAddress, 100, ethers.parseEther("1"), 10, true);
        
        // 添加第1个池子 (ERC20)
        await stake.addPool(await stakeToken.getAddress(), 200, ethers.parseEther("100"), 50, true);
        
        const pool = await stake.poolList(1);
        expect(pool.poolWeight).to.equal(200);
    });

    it("用户质押 ERC20 应该产生奖励", async () => {
        // 1. 初始化池子
        await stake.addPool(ethers.ZeroAddress, 100, 0, 10, true); // PID 0
        await stake.addPool(await stakeToken.getAddress(), 100, 0, 10, true); // PID 1
        
        // 2. 用户授权并质押
        const depositAmount = ethers.parseEther("1000");
        await stakeToken.connect(user1).approve(await stake.getAddress(), depositAmount);
        await stake.connect(user1).deposit(1, depositAmount);

        // 3. 模拟区块经过
        await mine(100);

        // 4. 检查是否有奖励产生
        // 注意：合约中的 updatePool 在 claimRewards 中会被调用
        const beforeBalance = await stakeToken.balanceOf(user1.address);
        await stake.connect(user1).claimRewards(1);
        const afterBalance = await stakeToken.balanceOf(user1.address);
        
        expect(afterBalance).to.be.gt(beforeBalance);
    });

    it("解质押后的提取应该受锁定区块限制", async () => {
        const lockBlocks = 20;
        await stake.addPool(ethers.ZeroAddress, 100, 0, 10, true);
        await stake.addPool(await stakeToken.getAddress(), 100, 0, lockBlocks, true);

        const amount = ethers.parseEther("500");
        await stakeToken.connect(user1).approve(await stake.getAddress(), amount);
        await stake.connect(user1).deposit(1, amount);

        // 申请解质押
        await stake.connect(user1).unstake(1, amount);

        // 立即尝试提取（应该失败或提取为0）
        const balBefore = await stakeToken.balanceOf(user1.address);
        await stake.connect(user1).withdraw(1);
        expect(await stakeToken.balanceOf(user1.address)).to.equal(balBefore);

        // 模拟经过锁定区块
        await mine(lockBlocks + 1);

        // 再次提取
        await stake.connect(user1).withdraw(1);
        expect(await stakeToken.balanceOf(user1.address)).to.be.gt(balBefore);
    });
});