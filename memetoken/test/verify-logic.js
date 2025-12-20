const { ethers, deployments } = require("hardhat");

async function main() {
    const [owner, user] = await ethers.getSigners();
    const tokenDeployment = await deployments.get("ShiBaToken");
    const token = await ethers.getContractAt("ShiBaToken", tokenDeployment.address);

    console.log("1. 检查初始余额...");
    const balance = await token.balanceOf(owner.address);
    console.log(`Owner 余额: ${ethers.formatEther(balance)}`);

    console.log("2. 尝试向普通用户转账（测试免税/收税）...");
    const transferAmount = ethers.parseEther("1000");
    await token.transfer(user.address, transferAmount);
    
    const userBalance = await token.balanceOf(user.address);
    console.log(`User 收到金额: ${ethers.formatEther(userBalance)}`);
    // 如果 Owner 是免税的，User 应该收到完整的 1000
}

main().catch(console.error);