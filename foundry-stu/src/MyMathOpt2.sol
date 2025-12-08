// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MyMathOpt2 {
    
    event Opt(address indexed sender, uint256 a, uint256 b,uint256 result);

    
    
    
    function add(uint256 a, uint256 b) external  returns (uint256 r) {
        unchecked {
            r = a+b;
        }
        emit Opt(msg.sender,a, b, r);
    }

    function sub(uint256 a, uint256 b) external  returns (uint256 r) {
        require(a >  b, "a must be greater than b");
        unchecked {
            r = a-b;
        }
        emit Opt(msg.sender,a,b,r);
    }

    function mul(uint256 a, uint256 b) external  returns (uint256 r) {
        unchecked {
            r = a*b;
        }
        emit Opt(msg.sender,a,b,r);
    }

    function div(uint256 a, uint256 b) external returns (uint256 r) {
        require(b > 0, "b must be greater than 0"); 
        unchecked {
            r = a/b;
        }
        emit Opt(msg.sender,a,b,r);
    }
}