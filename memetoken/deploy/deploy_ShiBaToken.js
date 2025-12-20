const fs = require("fs");
const path = require("path");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts(); // 会自动从 config 取第一个账号


    console.log("开始部署 ShiBaToken...");

    // 使用插件原生的 deploy 方法
    const result = await deploy("ShiBaToken", {
        from: deployer,
        args: [deployer, deployer, deployer, deployer],
        log: true,
        waitConfirmations: 1,
    });

    console.log(`ShibaToken 部署成功: ${result.address}`);

    // 保存到你指定的缓存路径
    const cacheDir = path.resolve(__dirname, "../.cache");
    if (!fs.existsSync(cacheDir)) {
        fs.mkdirSync(cacheDir, { recursive: true });
    }
    const storePath = path.join(cacheDir, "deployedAddresses.json");

    fs.writeFileSync(storePath, JSON.stringify({
        ShiBaToken: result.address,
        abi: result.abi
    }, null, 2));
};

module.exports.tags = ['deployShiBaToken'];