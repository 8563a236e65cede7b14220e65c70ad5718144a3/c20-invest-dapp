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
contract C20InvestInitializable is C20InvestBase, Initializable, OwnableInitializable, SuspendableInitializable {
    /// @dev Initializer for this contract
    /// @param owners An array of addresses that will be assigned
    /// ownership of the contract. See :ref:Ownable for usage
    /// @param c20Address The address of the currently active
    /// C20 smart contract. Required to initialize the C20
    /// instance
    function initialize (address[] memory owners, address c20Address)
    public
    initializer {
        OwnableInitializable.initialize(owners);
        SuspendableInitializable.initialize();
        c20Instance = C20(payable(c20Address));
    }

    /// @dev Allows changing the address of the C20 contract in the
    /// event of an upgrade
    /// @param c20Address The address of the currently active
    /// C20 smart contract
    function setC20Address(address c20Address) public onlyOwner {
        _setC20Address(c20Address);
    }

}
