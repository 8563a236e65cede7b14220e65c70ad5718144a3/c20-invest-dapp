// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./c20_base/C20.sol";
import "./access/Ownable.sol";
import "./math/SafeMathNew.sol";


contract C20Invest is Ownable {
    using SafeMathNew for uint256;

    C20 c20;

    uint256 MIN_INVESTMENT = 0.1 ether;
    mapping (address => uint256) public userBalances;
    mapping (address => uint256) public requestTime;

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
        require(
            requestTime[msg.sender] < c20.previousUpdateTime(),
            "C20Invest: price has not updated yet"
        );
        require(
            userBalances[msg.sender] > 0,
            "C20Invest: user has no ether for conversion"
        );

        uint256 numTokens = 0;
        uint256 priceNumerator;
        uint256 priceDenominator;
        (priceNumerator, priceDenominator) = c20.currentPrice();
        numTokens = priceNumerator.mul(userBalances[msg.sender]);
        numTokens = numTokens.div(priceDenominator);

        userBalances[msg.sender] = 0;
        c20.transferFrom(address(this), msg.sender, numTokens);
    }

    receive() external payable {
        buy();
    }

    fallback() external payable {

    }

}
