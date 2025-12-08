// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MyMathOpt {
    
    event Add(address indexed sender,uint256 a, uint256 b,uint256 result);
    event Sub(address indexed sender,uint256 a, uint256 b,uint256 result);
    event Mul(address indexed sender,uint256 a, uint256 b,uint256 result);
    event Div(address indexed sender,uint256 a, uint256 b,uint256 result);

    
    
    function add(uint256 a, uint256 b) public  returns (uint256) {
        uint256 r;
        unchecked {
            r = a+b;
        }
        emit Add(msg.sender,a, b, r);
        return r;
    }

    function sub(uint256 a, uint256 b) public  returns (uint256) {
        require(a >  b, "a must be greater than b");
        uint256 r;
        unchecked {
            r = a-b;
        }
        emit Sub(msg.sender,a,b,r);
        return r;
    }

    function mul(uint256 a, uint256 b) public  returns (uint256) {
        uint256 r;
        unchecked {
            r = a*b;
        }
        emit Mul(msg.sender,a,b,r);
        return r;
    }

    function div(uint256 a, uint256 b) public returns (uint256) {
        require(b > 0, "b must be greater than 0"); 
        uint256 r;
        unchecked {
            r = a/b;
        }
        emit Div(msg.sender,a,b,r);
        return r;
    }
}