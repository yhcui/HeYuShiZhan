// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Test} from "forge-std/Test.sol";
import {MyMath} from "../src/MyMath.sol";
import "forge-std/console.sol";

contract MyMathTest is Test{

    MyMath public myMath;

    function setUp() public {
        myMath = new MyMath();
    }

    function testAdd() public {
        assertEq(myMath.add(1,2),3);
    }

    function testSub() public {
        assertEq(myMath.sub(5,2),3);
    }

    function testMul() public {
        assertEq(myMath.mul(5,2),10);
    }

    function testDiv() public {
        console.log(myMath.div(1,2));
        assertEq(myMath.div(10,2),5);
    }

}