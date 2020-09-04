// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

/// @title Ownership Base Contract
/// @author Invictus Capital
/// @notice Helper contract for access control
/// @dev Contract module to allow ownership of another contract that
/// inherits from it. Ownership is assigned to the account which
/// deploys the contract if an empty array is provided to the
/// constructor, otherwise the addresses supplied are assigned
/// ownership.
///
/// Allows ownership to be transferred and multiple owners. Ownership
/// can be revoked as long as there is at least one owner. If there
/// is only a single owner, ownership revocation will not be possible
/// as it would render functions that check for ownership unusable.
///
/// Exposes a few modifiers and convenience functions to restrict
/// access of functions to the owner of the contract.
contract Ownable {

    /// @dev Array of owner addresses
    address[] private _owners;

    /// Constructor for Ownable
    /// @param owners An array of addresses representing the
    /// initial owners of the contract. Pass an empty array to
    /// set the sole owner of the contract as the address which deployed
    /// the contract
    constructor(address[] memory owners) {
        uint i;
        uint n = owners.length;
        if (n == 0) {
            _owners.push(msg.sender);
        } else {
            for (i=0; i<n; i++){
                _owners.push(owners[i]);
            }
        }
    }

    function get_owners()
    public
    view
    returns (address[] memory owners){
        return _owners;
    }

}
