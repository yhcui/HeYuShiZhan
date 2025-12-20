require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("@nomicfoundation/hardhat-ethers"); // 确保引入了此插件

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    // 这里配置多个编译器版本 -- 因为uniswap的合约使用了不同的solidity版本
    compilers: [
      {
        version: "0.8.28", // 你的 ShiBaToken 使用的版本
        settings: {
          optimizer: { enabled: true, runs: 200 }
        }
      },
      {
        version: "0.6.6",  // UniswapV2Router02 需要的版本
        settings: {
          optimizer: { enabled: true, runs: 200 }
        }
      },
      {
        version: "0.5.16", // UniswapV2Factory 需要的版本
        settings: {
          optimizer: { enabled: true, runs: 200 }
        }
      }
    ]
  },
  settings: { optimizer: { enabled: true, runs: 200 } },
  namedAccounts: {
    deployer: {
      default: 0, // 第一个账户作为部署者
    },
    marketingWallet: {
      default: 1, // 第二个账户作为营销钱包
    },
    liquidityWallet: {
      default: 2, // 第三个账户作为流动性钱包
    },
    user1: {
      default: 3, // 第四个账户作为测试买家1
    },
    user2: {
      default: 4, // 第五个账户作为测试买家2
    },
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
  },
};