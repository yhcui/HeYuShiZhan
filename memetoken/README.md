# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
```


# 部署相关知识
##  Sepolia 测试网
WETH  合约地址：  0x7b79995e5f793a07bc00c21412e50ecae098e7f9
V2  Router地址： 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008
V2 Factory地址： 0x7E0987E5b3a30e3f2828572Bb659A548460a3003

## 如何进行本地mock
### 准备 Mock 合约源码
npm install @uniswap/v2-core @uniswap/v2-periphery  
或者
contracts/mocks/MockUniswap.sol，直接导入
import "@uniswap/v2-core/contracts/UniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/UniswapV2Router02.sol";


## 验证步骤
1、编译： npx hardhat compile
编译可能会报错-- 因为需要支持多版本编译
    当你在 deploy 函数的 contract 字段中写下 @uniswap/... 这种路径时，Hardhat 的插件系统会像一个“侦探”一样去 node_modules 里翻找。只要你的 compilers 数组里有对应的版本，它就能单独为那个库文件启用对应的编译器，而不会干扰你主合约的 0.8.28 环境。

2、 运行部署（本地模拟网）： npx hardhat deploy --tags mocks


3、 运行部署ShiBaToken 
npx hardhat deploy --tags ShiBaToken --network localhost

4、验证 npx hardhat run test/verify-logic.js --network localhost  

## 内存测试
npx hardhat test test/ShiBaToken.test.js

## 启动节点整体测试
1、 启动本地节点
npx hardhat node

2、执行测试
整个test目录：npx hardhat test --network localhost  
test目录下某个文件：npx hardhat test test/ShiBaToken.test.js --network localhost  

只运行名称包含 "税收" 的测试用例 npx hardhat test --network localhost --grep "税收"  


# 代码设计
## 税费
买入税  
卖出税  
转账税  

## 税费分配
营销  
销毁  
流动性

## 交易限制
最大交易量  
最大持有量
交易间隔  


# 角色
1. owner

# 功能

### 初始化
1、营销钱包   
2、流动性钱包 
3、uniswap v2信息
4、市场
5、税费信息  
6、交易限制信息
7、合约自动触发swap的阈值
8、不需要收手续费地址
9、不需要进行限制地址
10、铸造 -- 给合约部署者，而不是给合约

###  手动token换eth并添加流动性 owner
1、swap: token转为eth
2、添加流动性
3、瓜分转为流动性的数量（这里合约的余额）

### 紧急提取ETH owner

### 紧急提取代币 owner

### 转账方法重写 核心

### 代币换ETH

### 应用交易限制？

### 计算费用

### 添加流动性


### 启用禁用交易 owner
1、启用禁用转账  
2、启用禁用代币交换(代币转ETH)以及添加流动性

###  设置自动化做市商对 owner
1、根据to或from判断是bug还是sell

### 设置税率 owner

### 设置交易限制 owner

### 设置营销钱包 owner

### 设置流动性钱包 owner

### 设置交易限制 owner

### 设置黑名单 owner

### 设置免税名单 owner

### 设置免限制名单 owner


### 获取代币信息

### 获取当前费用费率信息

### 获取限制信息

### 获取分配信息





# 变量
1. 营销钱包
2. 销毁钱包
3. 营销比例


