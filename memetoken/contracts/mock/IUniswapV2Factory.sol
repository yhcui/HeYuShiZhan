// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    // 创建交易对
    function createPair(address tokenA, address tokenB) external returns (address pair);

    // 【必须新增这一行】用于查询已存在的交易对地址
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}