const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    console.log("--- 部署 Mock 环境 ---");

    // 1. 部署 WETH
    // 检查合约是否需要部署 $\rightarrow$ 发送交易 $\rightarrow$ 等待确认 $\rightarrow$ 保存结果。
    /*
        const result = await deploy("ContractName", {
            from: deployer,           // 部署者的地址
            args: [arg1, arg2],       // 传递给构造函数的参数
            log: true,                // 是否在控制台打印部署日志（地址、Gas 等）
            deterministicDeployment: false, // 是否使用 CREATE2 确定性部署
            proxy: {                  // 如果是可升级合约，在这里配置代理信息
                proxyContract: "OpenZeppelinTransparentProxy",
            },
            waitConfirmations: 1,     // 等待多少个区块确认
        });

        deploy 的“智能”特性
        1、幂等性（Idempotency）：它会检查 deployments/网络名/ContractName.json。
            如果该文件已存在，且字节码、构造参数均未改变，它会跳过部署。这在网络波动中断后重新部署时非常有用。

        2、自动处理 Artifacts：它会自动从 artifacts 文件夹读取编译好的字节码。
    */
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
    // 生成文件：deployments/localhost/MockRouter.json
    const router = await deploy("MockRouter", {
        from: deployer,
        args: [factory.address, weth.address],
        log: true,
    });

    // 【重要】为了让 Hardhat Test 能够通过 "UniswapV2Router02" 名字找到它
    // 我们手动给这个部署起个别名，或者在测试里改用 MockRouter 名字获取
    // 生成文件：deployments/localhost/UniswapV2Router02.json
    await deployments.save("UniswapV2Router02", router);
    
    console.log("Mock Router 部署成功:", router.address);
    /*
        为什么要这样设计？（实战意义）
        这种做法被称为 “依赖倒置”。

        生产环境：在主网部署时，你不需要部署 Mock。你会先手动创建一个 UniswapV2Router02.json，里面只写上主网路由的地址（0x7a25...）。

        测试环境：你部署 MockRouter，然后用 save 把它也伪装成 UniswapV2Router02。

        这样，你的 ShiBaToken 部署脚本就不需要改动任何代码，无论在哪个网络运行，它只需要寻找名为 UniswapV2Router02 的记录即可。
    */
    
};

module.exports.tags = ["mocks"];
