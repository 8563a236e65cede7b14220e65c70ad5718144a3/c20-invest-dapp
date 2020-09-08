// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./c20_base/C20.sol";
import "./access/Ownable.sol";


contract C20Invest is Ownable {
    C20 c20;

    uint MIN_INVESTMENT = 0.1 ether;
    mapping (address => uint) public userBalances;
    mapping (address => uint) public requestTime;
    
    constructor (address[] memory owners, address payable c20Address)
    Ownable(owners) {
        c20 = C20(c20Address);
    }

    function setC20Address(address payable C20Address) public onlyOwner {
        c20 = C20(C20Address);
    }
    
    function buy() public payable {
        require(
            msg.value >= MIN_INVESTMENT, 
            "C20Invest: ether received below minimum investment"
        );
        requestTime[msg.sender] = c20.previousUpdateTime();
        userBalances[msg.sender] += msg.value;
    }
    
    function getTokens() external {
        require(requestTime[msg.sender] < c20.previousUpdateTime());
        require(userBalances[msg.sender] > 0);
        userBalances[msg.sender] = 0;
        uint numTokens = 0;
        // TODO: implement pricing logic
        c20.previousUpdateTime()

        c20.transferFrom(address(this), msg.sender, numTokens);
    }

    receive() external payable {
        buy();
    }

    fallback() external payable {

    }

}
