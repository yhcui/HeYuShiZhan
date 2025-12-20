const fs = require("fs");
const path = require("path");
module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, get } = deployments;
    const { deployer, marketingWallet, liquidityWallet,user1,user2 } = await getNamedAccounts();

    // 动态获取刚才部署的 Mock Router 地址
    const MockRouter = await get("UniswapV2Router02");
    const routerAddress = MockRouter.address;

    const MARKETING_WALLET = marketingWallet; // 确保地址完整 42 位
    const LIQUIDITY_WALLET = liquidityWallet;
    const BURN_ADDRESS = "0x000000000000000000000000000000000000dEaD";

    console.log("--- 开始部署 ShiBaToken ---");

    await deploy("ShiBaToken", {
        from: deployer,
        args: [
            MARKETING_WALLET, 
            LIQUIDITY_WALLET, 
            BURN_ADDRESS, 
            routerAddress
        ],
        log: true,
    });
};

// 确保在运行 ShiBaToken 部署前先运行 mocks 脚本
module.exports.dependencies = ["mocks"]; 
module.exports.tags = ["ShiBaToken"];