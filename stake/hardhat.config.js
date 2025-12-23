// const { network, ethers } = require("hardhat");

require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy"); // ✅ 必须加上这行，否则 namedAccounts 不生效
require("dotenv").config();
require("@nomicfoundation/hardhat-ethers"); // 确保引入了此插件
/** @type import('hardhat/config').HardhatUserConfig */
const { SEPOLIA_RPC_URL, PRIVATE_KEY, ETHERSCAN_API_KEY } = process.env;
module.exports = {
  solidity: "0.8.28",
  networks: {
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 11155111,
    },
    localhost: {
      url: "http://127.0.0.1:8545/",
    },

  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },

  namedAccounts: {
    deployer: {
      default: 0,
      11155111: 0,
    },
  },
};
