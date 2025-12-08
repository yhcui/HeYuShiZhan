// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Test} from "forge-std/Test.sol";
import {MyMathOpt} from "../src/MyMathOpt.sol";
import "forge-std/console.sol";

contract MyMathTest is Test{

    MyMathOpt public myMath;

    function setUp() public {
        myMath = new MyMathOpt();
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