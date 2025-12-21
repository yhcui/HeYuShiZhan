// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakeToken is ERC20 {
    constructor() ERC20("StakeToken", "STK") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function decimals() public view override returns (uint8) {
        return 18;
    }

}