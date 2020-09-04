// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

/// @title Ownership Base Contract
/// @author Invictus Capital
/// @notice Helper contract for access control
/// @dev Contract module to allow ownership of the contract that
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
/// access of functions to the owners of the contract. Essentially
/// allows root access for contracts that inherit from it
contract Ownable {

    /// @dev Array of owner addresses
    address[] private _owners;

    /// @notice Constructor for Ownable
    /// @dev Pass an empty array to set the sole owner of the contract
    /// as the address which deployed the contract or a
    /// non-empty array to explicitly set the owner addresses
    /// @param owners An array of addresses representing the
    /// initial owners of the contract.
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

    /// @notice Get the current list of owners for the contract
    /// @dev Allows indirect access to the private variable _owners.
    /// May be expensive if the array is large in which case an implementation
    /// that uses a mapping instead of an array would be preferred
    /// @return owners An array of owner addresses
    function getOwners()
    public
    view
    returns (address[] memory owners){
        return _owners;
    }

    /// @notice Check if a given address is an owner
    /// @dev Walks through the _owners array to find out if the
    /// address is currently an owner of the contract
    /// @return isOwner true if address is found, false otherwise
    function checkOwner(address ownerAddress)
    public
    view
    returns (bool isOwner) {
        uint i;
        uint n = _owners.length;

        for(i=0; i<n; i++){
            if (ownerAddress == _owners[i]) {
                return true;
            }
        }

        return false;
    }

    modifier onlyOwner() {
        require(
            checkOwner(msg.sender),
            "Ownable: caller is not the owner"
        );
        _;
    }

}
