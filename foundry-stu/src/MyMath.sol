// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MyMath {
    
    event Add(address sender,uint256 a, uint256 b,uint256 result);
    event Sub(address sender,uint256 a, uint256 b,uint256 result);
    event Mul(address sender,uint256 a, uint256 b,uint256 result);
    event Div(address sender,uint256 a, uint256 b,uint256 result);

    
    
    function add(uint256 a, uint256 b) public  returns (uint256) {
        emit Add(msg.sender,a, b, a+b);
        return a + b;
    }

    function sub(uint256 a, uint256 b) public  returns (uint256) {
        require(a >  b, "a must be greater than b");
        emit Sub(msg.sender,a,b,a-b);
        return a - b;
    }

    function mul(uint256 a, uint256 b) public  returns (uint256) {
        emit Mul(msg.sender,a,b,a*b);
        return a * b;
    }

    function div(uint256 a, uint256 b) public returns (uint256) {
        require(b > 0, "b must be greater than 0"); 
        emit Div(msg.sender,a,b,a/b);
        return a / b;
    }
}