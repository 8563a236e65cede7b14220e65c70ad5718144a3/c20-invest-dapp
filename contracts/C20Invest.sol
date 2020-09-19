// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./C20InvestBase.sol";

/// @title C20Invest Smart Contract
/// @author Invictus Capital
/// @notice Base Contract for C20 resale
/// @dev This version of the contract is used for unit tests and
/// utilizes a constructor versus an initializer. It can be used
/// to test whether errors result from the :sol:contract:`C20InvestBase` code or
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

    /// @dev Emitted when all tokens are transferred out of this
    /// contract
    /// @param to The address that will receive the tokens
    /// @param sender The account which triggered the transfer
    /// @param amount The number of tokens transferred
    event AllTokensTransferred(address indexed to, address indexed sender, uint256 amount);

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
        _buy(msg.sender, msg.value);
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

    /// @dev Transfers all tokens within this account to the
    /// supplied address. The use case for this is upgrade to
    /// the next version of this contract. The tokens can be
    /// sent back to the fund wallet for transfer into the
    /// updated contract
    /// @param to The address to transfer the tokens to
    function transferTokens(address to) public onlyOwner {
        uint256 tokenBalance = c20Instance.balanceOf(address(this));
        require(tokenBalance > 0, "C20Invest: contract ha zero token balance");
        c20Instance.transfer(to, tokenBalance);
        emit AllTokensTransferred(to, msg.sender, tokenBalance);
    }

    /// @dev The receive function is triggered when ether is sent to the
    /// contract. It is just a simple wrapper for buy().
    receive() external payable {
        buy();
    }

}
