
# 区分环境
npm install --save-dev dotenv

在项目根目录下创建一个 .env 文件

# 本地测试环境
npx hardhat deploy --tags StakeToken --network localhost

# SEPOLIA 测试环境

npx hardhat deploy --tags StakeToken --network localhost