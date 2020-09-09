// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./c20_base/C20.sol";
import "./access/Ownable.sol";
import "./math/SafeMathNew.sol";


contract C20Invest is Ownable {
    using SafeMathNew for uint256;

    C20 c20Instance;

    uint256 MIN_INVESTMENT = 0.1 ether;
    mapping (address => uint256) public userBalances;
    mapping (address => uint256) public requestTime;

    constructor (address[] memory owners, address c20Address)
    Ownable(owners) {
        c20Instance = C20(payable(c20Address));
    }

    function setC20Address(address C20Address) public onlyOwner {
        c20Instance = C20(payable(C20Address));
    }
    
    function buy() public payable {
        require(
            msg.value >= MIN_INVESTMENT, 
            "C20Invest: ether received below minimum investment"
        );
        requestTime[msg.sender] = c20Instance.previousUpdateTime();
        userBalances[msg.sender] += msg.value;
    }
    
    function getTokens() external {
        require(
            requestTime[msg.sender] < c20Instance.previousUpdateTime(),
            "C20Invest: price has not updated yet"
        );
        require(
            userBalances[msg.sender] > 0,
            "C20Invest: user has no ether for conversion"
        );

        uint256 contractTokenBalance = c20Instance.balanceOf(address(this));

        require(
             contractTokenBalance > 0,
            "C20Invest: no tokens left in this account"
        );

        uint256 numTokens = 0;
        uint256 priceNumerator;
        uint256 priceDenominator;
        uint256 refund = 0;
        (priceNumerator, priceDenominator) = c20Instance.currentPrice();
        numTokens = priceNumerator.mul(userBalances[msg.sender]).div(priceDenominator);

        if (numTokens > contractTokenBalance) {
            refund = userBalances[msg.sender].sub(contractTokenBalance.mul(priceDenominator).div(priceNumerator));
            numTokens = contractTokenBalance;
        }

        userBalances[msg.sender] = 0;
        c20Instance.transfer(msg.sender, numTokens);
        if (refund != 0) {
            msg.sender.transfer(refund);
        }
    }

    receive() external payable {
        buy();
    }

    fallback() external payable {

    }

}
