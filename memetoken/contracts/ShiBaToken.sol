// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";    
import "./mock/IUniswapV2Router2.sol";
import "./mock/IUniswapV2Factory.sol";

contract ShiBaToken is ERC20, Ownable {

    uint256 private constant MAX_SUPPLY = 1_000_000_000 * (10 ** 18); // 10亿代币，18位小数

    uint256 private constant INITIAL_SUPPLY = MAX_SUPPLY; // 10亿代币，18位小数


    uint256 public swapThreshold;

    // 税费
    struct TaxRate {
        uint256 buyTax;
        uint256 sellTax;
        uint256 transferTax;
    }

    TaxRate public taxRate ;

    //税费分配
    struct TaxAllot {
        uint256 liquidity;
        uint256 marketing;
        uint256 burn;
    }

    TaxAllot public taxAllot;


    struct TradeLimit {
        uint256 maxTxAmount; // 最大交易量
        uint256 maxWalletAmount; // 最大钱包持有量
        uint256 minTimeBetweenTx; // 最小交易间隔时间
        bool isTradeLimit;  // 是否启用交易限制
    }

    TradeLimit public tradeLimit;

    address public marketingWallet;

    address public liquidityWallet;

    address public burnAddress = address(0xdEaD);

    IUniswapV2Router2 public uniswapV2Router;

    address public uniswapV2Pair;


    // 未启用，则只允许免手续费的用户
    bool public tradingEnabled;

    //在交易中是否允许交换及添加Liquidity
    bool public swapEnabled;

    //互斥
    bool public inSwap;

    // 免手续费名单
    mapping(address => bool) public isExcludedFromFee;

    // 免限制名单
    mapping(address => bool) public isExcludedLimit;

    // AMM交易对
    mapping(address => bool) public ammPairs;

    // 最后交易时间 -- address为from时间
    mapping(address => uint256) public lastTxTime;


    //黑名单
    mapping(address => bool) public isBlacklisted;

    //铸造
    event MINTEVENT(address indexed to, uint256 amount);

    //启用禁用交易
    event ENABLETRADINGEVENT(address indexed add,bool enable);

    modifier lockInSwap {
        inSwap = true;
        _;
        inSwap = false;
    }


    constructor(address _marketingWallet,
        address _liquidityWallet, 
        address _burnAddress,
        address routerAddress
        ) 
        ERC20("ShiBaToken", "SHIBAT")  Ownable(msg.sender){

        marketingWallet = _marketingWallet;

        liquidityWallet = _liquidityWallet;

        burnAddress = _burnAddress;

        require(routerAddress != address(0), "router address is zero");

        // uniswapV2Router = IUniswapV2Router2(routerAddress);
        // uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _setAmmPairs(uniswapV2Pair, true);
        



        taxRate = TaxRate({
            buyTax: 500,
            sellTax: 1000,
            transferTax: 200
        });

        taxAllot = TaxAllot({
            liquidity: 300,
            marketing: 500,
            burn: 200
        });

        tradeLimit = TradeLimit({
            maxTxAmount: INITIAL_SUPPLY *1 / 10000, // 0.01% 的初始供应量
            maxWalletAmount:  INITIAL_SUPPLY *1 / 100, // 
            minTimeBetweenTx: 10,
            isTradeLimit: true
        });

        swapThreshold = INITIAL_SUPPLY * 1 / 100000; // 0.001% 的初始供应量

        
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[uniswapV2Pair] = true;
        isExcludedFromFee[marketingWallet] = true;
        isExcludedFromFee[liquidityWallet] = true;
        isExcludedFromFee[burnAddress] = true;

        isExcludedLimit[msg.sender] = true;
        isExcludedLimit[address(this)] = true;
        isExcludedLimit[uniswapV2Pair] = true;
        isExcludedLimit[marketingWallet] = true;
        isExcludedLimit[liquidityWallet] = true;
        isExcludedLimit[burnAddress] = true;

        
        _mint(msg.sender, INITIAL_SUPPLY);

        emit MINTEVENT(msg.sender, INITIAL_SUPPLY);

    }

    function handeSwapAndLiquify() external onlyOwner {
        // 交换及添加流动性逻辑
        uint256 balance = balanceOf(address(this));
        require(balance > 0, "no token");
        _swapAndLiquify(balance);
    }

    function _swapAndLiquify(uint256 amount) internal  lockInSwap { 
        require(amount > 0, "no token");
        // uint256 totalFee = taxRate.buyTax + taxRate.sellTax + taxRate.transferTax;
        uint256 totalAllot = taxAllot.liquidity + taxAllot.marketing + taxAllot.burn;
        require(totalAllot > 0, "no allot");
        // uint256 liquidityTokens = amount * taxAllot.liquidity / totalAllot / 2;
        uint256 liquidityTokens = amount*(taxAllot.liquidity)/(totalAllot)/(2);

        // uint256 marketingTokens = amount*(taxAllot.marketing)/(totalAllot);

        uint256 burnTokens = amount*(taxAllot.burn)/(totalAllot);

        if (burnTokens > 0) {
            super._transfer(address(this), burnAddress, burnTokens);
        }

        uint256 swapTokens = amount - liquidityTokens - burnTokens;

        uint256 ethbalanceBefore = address(this).balance;

        _swapTokensForEth(swapTokens);

        uint256 deltaBalance = address(this).balance-ethbalanceBefore;

        // eth分配给营销和流动性
        uint256 liquidityEth = deltaBalance * (taxAllot.liquidity)/ (totalAllot - taxAllot.burn)/2;
        uint256 marketingEth = deltaBalance - liquidityEth;


        if (liquidityEth > 0 && liquidityTokens > 0) {
            // 添加流动性
            _addLiquidity(liquidityTokens, liquidityEth);
        }
        if (marketingEth > 0) {
            payable(marketingWallet).transfer(marketingEth);
        }

    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // 会给msg.sender 转eth
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );

    }

    function getTokenInfo() external view returns (
        uint256 totalSupply_, 
        uint256 circulatingSupply_,
        uint256 balanceContract_, 
        uint256 burnedBalance_,
        bool tradingEnabled_, 
        bool swapEnabled_
        ) {
            totalSupply_ = totalSupply();
            balanceContract_ = balanceOf(address(this));
            circulatingSupply_ = totalSupply_ - (balanceContract_);
            burnedBalance_ = balanceOf(burnAddress);
            tradingEnabled_ = tradingEnabled;
            swapEnabled_ = swapEnabled;

    }
   //  提取合约地址中意外或错误发送的其他 ERC-20 代币。
    function emergencyWithdrawToken(address tokenAddress) external onlyOwner { 
        require(tokenAddress != address(this));

        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance =token.balanceOf(address(this));
        require(tokenBalance >0 , "no tokens");
        token.transfer(owner(), tokenBalance);
    }

    // 提取多余的eth
    function emergencyWithdrawETH() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        require(ethBalance >0 , "no eth");
        payable(owner()).transfer(ethBalance);
    }
  

    function _update(address sender, address recipient, uint256 amount ) internal override {
        if (sender != address(0)) {
            require(recipient != address(0), "transfer to zero address");
            require(!isBlacklisted[sender] && !isBlacklisted[recipient], "sender or recipient is blacklisted");

            if(tradeLimit.isTradeLimit) {
                _applyTradeLimit(sender, recipient, amount);
            }

            if (
                swapEnabled &&
                !inSwap&&
                !ammPairs[sender] && // not buy
                !isExcludedFromFee[sender] &&
                !isExcludedFromFee[recipient] &&
                balanceOf(address(this)) >= swapThreshold
            ) {
                _swapAndLiquify(swapThreshold);
            }

            bool takeFee = !inSwap;
            if (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
                takeFee = false;
            }
            uint256 fees = 0;
            if (takeFee) {
                fees = _calculateTax(sender, recipient, amount);
                if (fees > 0) {
                    super._update(sender, address(this), fees);
                    amount = amount - fees;
                }
            }
        }
        

        super._update(sender, recipient, amount);
        

    }

    function _applyTradeLimit(address sender, address recipient, uint256 amount) private { 
        if (!isExcludedLimit[sender] && !isExcludedLimit[recipient]) {
            require(amount < tradeLimit.maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if (!isExcludedLimit[recipient]) {
            uint256 recipientBalance = balanceOf(recipient);
            require(recipientBalance+(amount) <= tradeLimit.maxWalletAmount, "Recipient balance exceeds maxWalletAmount.");
        }

        if (!isExcludedLimit[sender] && 
            tradeLimit.minTimeBetweenTx > 0 &&
            ammPairs[recipient] ) {
            require(block.timestamp >= lastTxTime[sender] + tradeLimit.minTimeBetweenTx, "Please wait between transactions.");
            lastTxTime[sender] = block.timestamp;
        }

    }

    function _calculateTax(address sender, address recipient, uint256 amount) private view returns (uint256) {
        uint256 taxAmount = 0;
        if (ammPairs[sender]) {
            // 买入
            taxAmount = amount*(taxRate.buyTax)/(10000);
        } else if (ammPairs[recipient]) {
            // 卖出
            taxAmount = amount*(taxRate.sellTax)/(10000);
        } else {
            // 转账
            taxAmount = amount*(taxRate.transferTax)/(10000);
        }
        return taxAmount;

    }


    function enableTrading(bool _enabled) external onlyOwner {
        tradingEnabled = _enabled;
        swapEnabled = _enabled;

        emit ENABLETRADINGEVENT(msg.sender,_enabled);
    }
  


    function _setAmmPairs(address _uniswapV2Pair,bool r) internal {
        ammPairs[_uniswapV2Pair] = r;
    }
        
    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function setLiquidityWallet(address _liquidityWallet) external onlyOwner {
        liquidityWallet = _liquidityWallet;
    }

    function setBurnAddress(address _burnAddress) external onlyOwner {
        burnAddress = _burnAddress;
    }

    function setExcludedFromFee(address account, bool excluded) public onlyOwner {
        isExcludedFromFee[account] = excluded;
    }

    function setExcludedFromLimit(address account, bool excluded) public onlyOwner {
        isExcludedLimit[account] = excluded;
    }

    function setBlacklisted(address account, bool blacklisted) public onlyOwner {
        isBlacklisted[account] = blacklisted;
    }

    function setTaxRate(TaxRate calldata _tax) external onlyOwner {
        require(_tax.buyTax <= 10000 && _tax.sellTax <= 10000 && _tax.transferTax <= 10000, "Tax rates must be between 0 and 10000");
        require(_tax.buyTax + _tax.sellTax + _tax.transferTax <= 10000, "total rates must less than 100000");
        taxRate = _tax;
    }

    function setTaxAllot(TaxAllot calldata _allot) external onlyOwner {
        require(_allot.liquidity + _allot.marketing + _allot.burn == 100, "Total tax allocation must be 100");
        taxAllot = _allot;
    }

    function setTradeLimit(TradeLimit calldata _limit) external onlyOwner {
        tradeLimit = _limit;
    }

    function getTaxRate() external view returns (TaxRate memory) {
        return taxRate;
    }

    function getTaxAllot() external view returns (TaxAllot memory) {
        return taxAllot;
    }

    function getTradeLimit() external view returns (TradeLimit memory) {
        return tradeLimit;
    }

    receive() external payable {}
    
}