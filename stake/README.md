
# 区分环境
npm install --save-dev dotenv

在项目根目录下创建一个 .env 文件

# 本地测试环境 StakeToken
npx hardhat deploy --tags StakeToken --network localhost

# SEPOLIA 测试环境 StakeToken

npx hardhat deploy --tags StakeToken --network sepolia

# 手动验证合约 StakeToken

npx hardhat verify --network sepolia  0x883659A7c24581fbDbC014BA76646124a37A34F8


#  安装依赖
npm install --save-dev @openzeppelin/hardhat-upgrades

#  安装依赖
npx hardhat compile

# 测试
npx hardhat test test/Stake.test.js --network localhost  -- 用这个

npx hardhat run test/Stake.test.js --network localhost   -- 不用这个

# 部署
npx hardhat deploy --network sepolia --tags stake