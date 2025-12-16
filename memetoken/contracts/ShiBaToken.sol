// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";    
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./mock/IUniswapV2Router2.sol";
import "./mock/IUniswapV2Factory.sol";

contract ShiBaToken is ERC20, Ownable {

    using SafeMath for uint256;

    
    uint256 private constant MAX_SUPPLY = 1_000_000_000 * (10 ** 18); // 10亿代币，18位小数

    uint256 private constant INITIAL_SUPPLY = MAX_SUPPLY; // 10亿代币，18位小数


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

    EVENT MINTEVENT(address indexed to, uint256 amount);


    constructor(address _marketingWallet,
        address _liquidityWallet, 
        address _burnAddress,
        address routerAddress
        ) 
        ERC20("ShiBaToken", "SHIBAT")  Ownable(msg.sender){

        marketingWallet = _marketingWallet;

        liquidityWallet = _liquidityWallet;

        burnAddress = _burnAddress;

        uniswapV2Router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

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

        swapThreshold = INITIAL_SUPPLY * 5 / 100000; // 0.05% 的初始供应量

        
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



    function _setAmmPairs(address uniswapV2Pair,bool r) internal {
        ammPairs[uniswapV2Pair] = r;
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

    

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function setTaxRate(TaxRate memory _tax) external onlyOwner {
        require(_tax.buyTax <= 10000 && _tax.sellTax <= 10000 && _tax.transferTax <= 10000, "Tax rates must be between 0 and 10000");
        require(_tax.buyTax + _tax.selTax + _tax.transferTax <= 10000, "total rates must less than 100000");
        tax = _tax;
    }

    function setTaxAllot(TaxAllot memory _allot) external onlyOwner {
        require(_allot.liquidity + _allot.marketing + _allot.burn == 100, "Total tax allocation must be 100");
        taxAllot = _allot;
    }

    function setTradeLimit(TradeLimit memory _limit) external onlyOwner {
        tradeLimit = _limit;
    }

    function getTaxRate() external view returns (TaxRate memory) {
        return tax;
    }

    function getTaxAllot() external view returns (TaxAllot memory) {
        return taxAllot;
    }

    function getTradeLimit() external view returns (TradeLimit memory) {
        return tradeLimit;
    }

    
}