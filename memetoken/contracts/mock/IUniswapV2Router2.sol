// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

interface IUniswapV2Router2 {
    
    function factory() external pure returns  (address);

    function WETH() external pure returns (address);

    function swapExactTOkensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,// 目前固定[token,ETH]
        address to, // ETH接收到址
        uint deadline //截止时间
        
    ) external;

    function addLiquidityETH(
        address token, //  token地址
        uint amountTokenDesired, // 最多望的Token数量
        uint amountTokenMin, // 最少Token
        uint amountETHMin,//最少ETH
        address to,
        uint deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    


}