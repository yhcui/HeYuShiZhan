// 注意：不要在顶部 require("hardhat")，直接从参数中获取
module.exports = async ({ getNamedAccounts, deployments, network, run, ethers }) => {
    const { deploy } = deployments;
    // 1. 获取命名的账户地址（返回的是 string 类型的地址）
    const { deployer } = await getNamedAccounts(); 

    console.log(`准备部署，部署者地址: ${deployer}`);

    // 2. 部署合约
    const stakeToken = await deploy("StakeToken", {
        from: deployer, // 直接传地址字符串即可
        args: [], 
        log: true,
        waitConfirmations: network.config.chainId === 11155111 ? 6 : 1,
    });

    console.log(`StakeToken deployed at: ${stakeToken.address}`);

    // 3. 自动化验证 (仅在 Sepolia 且有 API Key 时运行)
    if (network.config.chainId === 11155111 && process.env.ETHERSCAN_API_KEY) {
        console.log("正在验证合约...");
        try {
            // 使用 run 调用 verify 任务
            await run("verify:verify", {
                address: stakeToken.address,
                constructorArguments: [],
            });
        } catch (e) {
            console.log("验证失败（可能已经验证过）:", e.message);
        }
        console.log(`查看地址: https://sepolia.etherscan.io/address/${stakeToken.address}`);
    }
}

module.exports.tags = ["StakeToken"];