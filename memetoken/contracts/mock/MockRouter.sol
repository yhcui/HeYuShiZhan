// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

// 简单的 WETH 接口，用于 deposit
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
}

contract MockRouter {
    address public immutable factory;
    address public immutable WETH;

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    // 模拟添加流动性逻辑
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint, // amountTokenMin
        uint, // amountETHMin
        address,
        uint // deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        // 【关键修复】：不使用 Library 自动计算，而是直接从 Factory 获取已存在的 Pair
        address pair = IUniswapV2Factory(factory).getPair(token, WETH);
        require(pair != address(0), "MockRouter: Pair not found");

        // 将 Token 从用户转入 Pair
        // 注意：这会触发 ShiBaToken 的 _update，因为 Owner 通常在免税名单，所以没问题
        SafeERC20Transfer(token, msg.sender, pair, amountTokenDesired);

        // 将 ETH 存入 WETH 并转入 Pair
        IWETH(WETH).deposit{value: msg.value}();
        require(IWETH(WETH).transfer(pair, msg.value), "MockRouter: WETH transfer failed");

        return (amountTokenDesired, msg.value, 0);
    }

    // 模拟 Swap 逻辑（用于测试自动换币）
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint, // amountOutMin
        address[] calldata path,
        address to,
        uint // deadline
    ) external {
        // 简化的 Mock 逻辑：直接把 Token 从合约转走，并把等值的 ETH 发给目标地址
        // 注意：为了测试通过，Mock 并不真的去 Pair 换钱，而是模拟这个过程
        address token = path[0];
        SafeERC20Transfer(token, msg.sender, address(this), amountIn);
        payable(to).transfer(address(this).balance);
        // 模拟换出的 ETH（实际开发中建议手动给 MockRouter 转一点 ETH 备用）
        payable(to).transfer(address(this).balance > 0 ? address(this).balance : 0);
    }

    // 辅助转账
    function SafeERC20Transfer(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "MockRouter: Transfer failed");
    }

    receive() external payable {}
}