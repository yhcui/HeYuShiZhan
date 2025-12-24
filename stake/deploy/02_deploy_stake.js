const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    // 1. 获取之前部署的 StakeToken 地址
    const stakeToken = await deployments.get("StakeToken");

    // 2. 准备初始化参数
    const currentBlock = await ethers.provider.getBlockNumber();
    const startBlock = currentBlock + 10;           // 10个区块后开始
    const endBlock = startBlock + 100000;           // 持续10万个区块
    const rewardPerBlock = ethers.parseEther("10"); // 每个区块奖励10个Token

    console.log("正在部署 Stake 代理合约...");

    const stakeProxy = await deploy("Stake", {
        from: deployer,
        args: [], // 构造函数为空
        log: true,
        // UUPS 代理配置
        proxy: {
            proxyContract: "UUPS",
            execute: {
                init: {
                    methodName: "initialize",
                    args: [
                        stakeToken.address,
                        startBlock,
                        endBlock,
                        rewardPerBlock
                    ],
                },
            },
        },
        waitConfirmations: network.config.chainId === 11155111 ? 6 : 1,
    });

    console.log(`Stake 代理地址: ${stakeProxy.address}`);
};

module.exports.dependencies = ["StakeToken"]; // 确保先部署代币

module.exports.tags = ["stake"];
