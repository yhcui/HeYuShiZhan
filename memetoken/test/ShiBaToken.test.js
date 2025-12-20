const { expect } = require("chai");
const { ethers, deployments, getNamedAccounts } = require("hardhat");

describe("ShiBaToken 深度逻辑测试", function () {
    let token, router, weth, owner, user1, user2, marketingWallet, liquidityWallet;
    let routerAddr, pairAddr;

beforeEach(async function () {
        // 1. 获取账户
        const namedAccounts = await getNamedAccounts();
        owner = await ethers.getSigner(namedAccounts.deployer);
        marketingWallet = namedAccounts.marketingWallet;
        liquidityWallet = namedAccounts.liquidityWallet;
        
        const signers = await ethers.getSigners();
        user1 = signers[3];
        user2 = signers[4];

        // 2. 部署环境
        // 确保部署顺序：先跑 mocks，再跑 ShiBaToken
        await deployments.fixture(["mocks", "ShiBaToken"]);
        
        // 3. 获取 Token 实例
        const tokenDeployment = await deployments.get("ShiBaToken");
        token = await ethers.getContractAt("ShiBaToken", tokenDeployment.address);
        
        // 4. 获取 Router 实例（关键修改点：使用合约中定义的接口名）
        const routerDeployment = await deployments.get("UniswapV2Router02");
        // 注意：这里的 "IUniswapV2Router02" 必须和你合约里定义的 interface 名字完全一致
        // router = await ethers.getContractAt(
        //     "contracts/mock/IUniswapV2Router02.sol:IUniswapV2Router02", 
        //     routerDeployment.address
        // );
        
        router = await ethers.getContractAt("MockRouter", routerDeployment.address);
        

        // 5. 【诊断加固】验证 WETH 状态
        const wethAddr = await router.WETH();
        const wethCode = await ethers.provider.getCode(wethAddr);
        if (wethCode === "0x") {
             console.error("CRITICAL ERROR: WETH address", wethAddr, "is empty!");
             throw new Error("WETH 合约未能在当前测试环境中部署成功，请检查 00_deploy_mocks.js");
        }

        // 6. 确保实例连接了 owner，以便后续进行 approve 和 addLiquidity 调用
        token = token.connect(owner);
        router = router.connect(owner);

        pairAddr = await token.uniswapV2Pair();

        const pairCode = await ethers.provider.getCode(pairAddr);
        console.log("Pair 地址:", pairAddr);
        console.log("Pair 代码是否存在:", pairCode.length > 2 ? "✅" : "❌");


    });

    describe("1. 基础配置检查", function () {
        it("应该正确分配初始供应量给 Owner", async function () {
            const ownerBalance = await token.balanceOf(owner.address);
            expect(ownerBalance).to.equal(ethers.parseEther("1000000000"));
        });

        it("Owner 应该在免税和免限制名单中", async function () {
            expect(await token.isExcludedFromFee(owner.address)).to.be.true;
            expect(await token.isExcludedLimit(owner.address)).to.be.true;
        });
    });

    describe("2. 流动性与交易开启", function () {
        it("应该能成功添加流动性", async function () {
            const tokenAmount = ethers.parseEther("1000000"); // 100万
            const ethAmount = ethers.parseEther("10"); // 10 ETH
            // === 强行体检开始 ===
            console.log("\n---------- [ 诊断报告 ] ----------");
            const tokenCode = await ethers.provider.getCode(token.target);
            const routerCode = await ethers.provider.getCode(router.target);
            const pairAddr = await token.uniswapV2Pair();
            const routerFactory = await router.factory();
            const routerWETH = await router.WETH();

            console.log("1. ShiBaToken 代码是否存在:", tokenCode.length > 2 ? "✅ 是" : "❌ 否 (地址空)");
            console.log("2. Router 代码是否存在:   ", routerCode.length > 2 ? "✅ 是" : "❌ 否 (地址空)");
            console.log("3. 合约记录的 Pair 地址:  ", pairAddr);
            console.log("4. Router 关联的 Factory: ", routerFactory);
            console.log("5. Router 关联的 WETH:    ", routerWETH);
            console.log("----------------------------------\n");
            // === 强行体检结束 ===
            await token.approve(router.target, tokenAmount);
            
            // 添加流动性
            await router.addLiquidityETH(
                token.target,
                tokenAmount,
                0, 0,
                owner.address,
                Math.floor(Date.now() / 1000) + 60,
                { value: ethAmount }
            );
            console.log("   ✅ 成功向 Uniswap 池子注入 100万 Token 和 10 ETH");
        });

        it("非免限制用户应受限于交易开关", async function () {
            // 默认 tradingEnabled 为 false
            await expect(token.connect(user1).transfer(user2.address, 100))
                .to.be.reverted; // 如果你在 _update 里写了 tradingEnabled 检查的话
        });
    });

    describe("3. 税收逻辑测试", function () {
        beforeEach(async function () {
            // 开启交易
            await token.enableTrading(true);
            // 先给 user1 点钱（Owner 转账免税）
            await token.transfer(user1.address, ethers.parseEther("10000"));
        });

        it("普通用户间转账应扣除 2% 的转账税", async function () {
            // 1. 【新增】前置条件：开启交易开关
            // 你的合约 _update 逻辑通常会判断 tradingEnabled，如果不开启，税收可能不生效
            await token.enableTrading(true);

            const amount = ethers.parseEther("1000");

            // 2. 【新增】前置条件：确保 user1 有钱（如果是从 owner 分发的，这步通常在之前已完成）
            // 并且确保 user1 和 user2 不在免税名单中
            await token.setExcludedFromFee(user1.address, false);
            await token.setExcludedFromFee(user2.address, false);

            // 3. 执行转账：user1 -> user2
            // 使用 .connect(user1) 确保 msg.sender 是 user1
            await token.connect(user1).transfer(user2.address, amount);
            
            // 4. 验证逻辑
            // 2% 税 = 20 token，用户应该收到 980
            const user2Balance = await token.balanceOf(user2.address);
            expect(user2Balance).to.equal(ethers.parseEther("980"));
            
            // 5. 验证合约地址是否收到了那 20 token 的税
            const contractBalance = await token.balanceOf(token.target);
            expect(contractBalance).to.equal(ethers.parseEther("20"));
            
            console.log("   ✅ 转账税收成功进入合约地址");
        });
    });

    describe("4. 交易限制 (TradeLimit) 测试", function () {
        beforeEach(async function () {
            await token.enableTrading(true);
        });

        it("不应允许单笔转账超过 maxTxAmount", async function () {
            // 初始 maxTxAmount 是 0.01% = 100,000
            const overLimit = ethers.parseEther("100001");
            await expect(token.connect(owner).transfer(user1.address, overLimit))
                .to.be.not.reverted; // Owner 免限制

            // User1 给 User2 转账超过限制
            await token.setExcludedFromLimit(user1.address, false);
            await expect(token.connect(user1).transfer(user2.address, overLimit))
                .to.be.revertedWith("Transfer amount exceeds the maxTxAmount.");
        });

        it("不应允许单人持币超过 maxWalletAmount", async function () {
            // 初始 maxWalletAmount 是 1% = 10,000,000
            const bigAmount = ethers.parseEther("10000001");
            await expect(token.transfer(user1.address, bigAmount))
                .to.be.revertedWith("Recipient balance exceeds maxWalletAmount.");
        });
    });

    describe("5. 自动换币与添加流动性 (SwapAndLiquify)", function () {
       it("合约余额达到阈值时应触发 Swap", async function () {
            await token.enableTrading(true);
            
            // 1. 获取阈值并存入 threshold + 1
            const threshold = await token.swapThreshold();
            // 确保余额严格大于阈值，触发 if (contractTokenBalance >= _swapThreshold)
            await token.transfer(token.target, threshold + 1n); 

            // 2. 【关键】：给 MockRouter 点钱，让它有能力发给营销钱包
            await owner.sendTransaction({
                to: router.target,
                value: ethers.parseEther("1") 
            });

            const beforeEth = await ethers.provider.getBalance(marketingWallet);
            
            // 3. 确保触发者 user1 不是免税账户
            await token.transfer(user1.address, ethers.parseEther("1000"));
            await token.setExcludedFromFee(user1.address, false);

            // 4. 执行转账触发逻辑
            // 这个动作会触发 ShiBaToken 内部调用 router.swapExactTokensForETH...
            await token.connect(user1).transfer(user2.address, ethers.parseEther("10"));

            // 5. 验证
            const afterEth = await ethers.provider.getBalance(marketingWallet);
            
            // 现在 afterEth 一定大于 beforeEth 了
            expect(afterEth).to.be.gt(beforeEth);
            
            const contractBalance = await token.balanceOf(token.target);
            expect(contractBalance).to.be.lt(threshold);
        });
    });
});