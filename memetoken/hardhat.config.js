require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("@nomicfoundation/hardhat-ethers"); // 确保引入了此插件

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  namedAccounts: {
    deployer: {
      default: 0, // 默认使用本地节点的第一个账户作为部署者
    },
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
  },
};