// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./C20InvestBase.sol";
import "./proxy/Initializable.sol";
import "./access/OwnableInitializable.sol";
import "./utils/SuspendableInitializable.sol";

/// @title C20InvestInitializable Smart Contract
/// @author Invictus Capital
/// @notice Base Contract for C20 resale
/// @dev This version of the contract is used for deployment and
/// utilizes an initializer versus a constructor. This will be
/// the contract that actually sits behind the proxy. Any differences
/// in unit tests between the C20Invest contract and this contract
/// can then be pinpointed to the proxy operations.
///
/// The contract is :sol:contract:`OwnableInitializable` to restrict access to the administrative
/// functions such as setC20Address and suspending the contract. The
/// contract is also :sol:contract:`SuspendableInitializable` and favours suspension over selfdestruct()
/// as in the former case a transaction sent to the contract address
/// (say after upgrade) will revert, whereas in the latter case, ether
/// sent to this address will be lost.
contract C20InvestInitializable is C20InvestBase, Initializable, OwnableInitializable, SuspendableInitializable {
    /// @dev Initializer for this contract
    /// @param owners An array of addresses that will be assigned
    /// ownership of the contract. See :ref:`Ownable` for usage
    /// @param c20Address The address of the currently active
    /// C20 smart contract. Required to initialize the C20
    /// instance
    function initialize (address[] memory owners, address c20Address)
    public
    initializer {
        OwnableInitializable.initialize(owners);
        SuspendableInitializable.initialize();
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
