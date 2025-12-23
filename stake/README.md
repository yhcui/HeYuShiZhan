
# 区分环境
npm install --save-dev dotenv

在项目根目录下创建一个 .env 文件

# 本地测试环境
npx hardhat deploy --tags StakeToken --network localhost

# SEPOLIA 测试环境

npx hardhat deploy --tags StakeToken --network sepolia

# 手动验证合约

npx hardhat verify --network sepolia  0x883659A7c24581fbDbC014BA76646124a37A34F8