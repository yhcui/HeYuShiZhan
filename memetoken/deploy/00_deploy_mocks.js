const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    console.log("--- 部署 Mock 环境 ---");

    // 1. 部署 WETH
    const weth = await deploy("WETH", { // 或者叫 MockWETH
        from: deployer,
        args: [],
        log: true,
    });
    console.log("WETH 实际部署地址:", weth.address);

    // 2. 部署 Factory (直接指向 npm 包路径)
    const factory = await deploy("UniswapV2Factory", {
        from: deployer,
        args: [deployer],
        // 关键：指定完整的内部路径
        contract: "UniswapV2Factory",
        // contract: "@uniswap/v2-core/contracts/UniswapV2Factory.sol:UniswapV2Factory",
        log: true,
    });

    // 3. 部署官方 Router (直接指向 npm 包路径)
    // const router = await deploy("UniswapV2Router02", {
    //     from: deployer,
    //     args: [factory.address, weth.address],
    //     // 关键：指定完整的内部路径
    //     contract: "UniswapV2Router02",
    //     // contract: "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol:UniswapV2Router02",
    //     log: true,
    // });


    // 3. 部署我们自定义的 MockRouter
    const router = await deploy("MockRouter", {
        from: deployer,
        args: [factory.address, weth.address],
        log: true,
    });

    // 【重要】为了让 Hardhat Test 能够通过 "UniswapV2Router02" 名字找到它
    // 我们手动给这个部署起个别名，或者在测试里改用 MockRouter 名字获取
    await deployments.save("UniswapV2Router02", router);
    
    console.log("Mock Router 部署成功:", router.address);
};

module.exports.tags = ["mocks"];
