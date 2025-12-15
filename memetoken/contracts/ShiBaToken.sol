// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";    
import "./mock/IUniswapV2Router2.sol";
import "./mock/IUniswapV2Factory.sol";

contract ShiBaToken is ERC20, Ownable {

    
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


    constructor(address _marketingWallet,
        address _liquidityWallet, 
        address _burnAddress ) 
        ERC20("ShiBaToken", "SHIBAT")  Ownable(msg.sender){
        _mint(msg.sender, INITIAL_SUPPLY);

    }


        
    
}