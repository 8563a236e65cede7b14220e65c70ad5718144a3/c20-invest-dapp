// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./C20InvestBase.sol";

/// @title C20Invest Smart Contract
/// @author Invictus Capital
/// @notice Base Contract for C20 resale
/// @dev This version of the contract is used for unit tests and
/// utilizes a constructor versus an initializer. It can be used
/// to test whether errors result from the C20InvestBase code or
/// whether they are coming from the proxying of functions.
/// This version tests the behaviour of the contract
/// when it is not behind a proxy.
///
/// The contract is :sol:contract:`Ownable` to restrict access to the administrative
/// functions such as setC20Address and suspending the contract. The
/// contract is also :sol:contract:`Suspendable` and favours suspension over selfdestruct()
/// as in the former case a transaction sent to the contract address
/// (say after upgrade) will revert, whereas in the latter case, ether
/// sent to this address will be lost.
contract C20Invest is C20InvestBase, Ownable, Suspendable {
    /// @dev Constructor for this contract
    /// @param owners An array of addresses that will be assigned
    /// ownership of the contract. See :ref:`Ownable` for usage
    /// @param c20Address The address of the currently active
    /// C20 smart contract. Required to initialize the C20
    /// instance
    constructor (address[] memory owners, address c20Address)
    Ownable(owners) {
        c20Instance = C20(payable(c20Address));
        MIN_INVESTMENT = 0.1 ether;
    }

    /// @dev Allows changing the address of the C20 contract in the
    /// event of an upgrade
    /// @param c20Address The address of the currently active
    /// C20 smart contract
    function setC20Address(address c20Address) public onlyOwner {
        _setC20Address(c20Address);
    }

    /// @dev Wrapper for _getTokens to suspend the contract if the
    /// token balance goes to zero
    function getTokens() external {
        uint256 refund = _getTokens();
        if(refund != 0) {
           _suspend();
        }
    }

    /// @dev Wrapper for suspend, marked with onlyOwner to restrict
    /// access
    function suspend() external onlyOwner {
        _suspend();
    }

    /// @dev Wrapper for resume, marked with onlyOwner to restrict
    /// access. We require a non-zero number of tokens to resume
    /// allowing deposits again
    function resume() external onlyOwner {
        require(
            c20Instance.balanceOf(address(this)) > 0,
            "C20Invest: cannot resume with zero token balance"
        );
        _resume();
    }

    /// @dev Wrapper for _buy marked with onlyActive to limit usage
    /// to only when the contract has tokens available
    function buy() public payable onlyActive {
        _buy();
    }

    /// @dev Helper function to get balance of ether in this contract
    /// @return balance The current ether balance within the contract
    function getContractEtherBalance()
    public
    view
    onlyOwner
    returns (uint256 balance) {
        return address(this).balance;
    }

    /// @dev Allows owner to withdraw ether stored
    /// @param amount The amount to withdraw in wei
    function withdrawBalance(uint256 amount) public onlyOwner
    {
        require(
            amount <= getContractEtherBalance(),
            "C20Invest: amount greater than available balance"
        );
        msg.sender.transfer(amount);
    }

    /// @dev The receive function is triggered when ether is sent to the
    /// contract. It is just a simple wrapper for buy().
    receive() external payable {
        buy();
    }

}
