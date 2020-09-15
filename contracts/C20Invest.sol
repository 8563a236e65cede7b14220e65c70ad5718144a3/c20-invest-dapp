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
contract C20Invest is C20InvestBase, Ownable, Suspendable {
    /// @dev Constructor for this contract
    /// @param owners An array of addresses that will be assigned
    /// ownership of the contract. See :ref:Ownable for usage
    /// @param c20Address The address of the currently active
    /// C20 smart contract. Required to initialize the C20
    /// instance
    constructor (address[] memory owners, address c20Address)
    Ownable(owners) {
        c20Instance = C20(payable(c20Address));
        currentTime = c20Instance.previousUpdateTime();
    }

    /// @dev Allows changing the address of the C20 contract in the
    /// event of an upgrade
    /// @param c20Address The address of the currently active
    /// C20 smart contract
    function setC20Address(address c20Address) public onlyOwner {
        _setC20Address(c20Address);
    }

    /// @dev Sets the oracle address.
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        _setOracleAddress(_oracleAddress);
    }
}
