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
    /// @dev Allows indirect read-only access to the private variable _owners.
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

    /// @notice Get the index of an owner address
    /// @dev Walks through the _owners array to find the index
    /// of the given address.
    /// @return index The index of the given address or -1 if
    /// not found
    function ownerIndex(address ownerAddress)
    public
    view
    returns (int index) {
        uint i;
        uint n = _owners.length;
        int address_index = -1;

        for(i=0; i<n; i++){
            if (ownerAddress == _owners[i]) {
                address_index = int(i);
                break;
            }
        }

        return address_index;
    }

    /// @dev Guard against non-owners calling privileged functions
    modifier onlyOwner() {
        require(
            checkOwner(msg.sender),
            "Ownable: caller is not the owner"
        );
        _;
    }

    /// @notice Adds a new owner for the contract
    /// @dev Restricted to existing owners. Checks
    /// that the given address is not already an owner
    /// @param newOwner The address to grant root privileges to
    function addOwner(address newOwner)
    public
    onlyOwner
    {
        require(
            !checkOwner(newOwner),
            "Ownable: owner already exists"
        );
        _owners.push(newOwner);
    }

    /// @notice Remove an address from owners list
    /// @dev Restricted to existing owners.
    /// This could allow a malicious actor to take complete
    /// control of the contract by removing all other owners.
    /// Trust is paramount when assigning ownership. To mitigate this,
    /// one could require two owners to call the removeOwner() function
    /// and deletion would occur on the second call. Does not allow
    /// removal of ownership if there is just a single owner.
    /// @param owner The address to revoke root privileges from
    function removeOwner(address owner)
    public
    onlyOwner
    {
        require(
            _owners.length > 1,
            "Ownable: cannot remove only owner"
        );
        int index = -1;

        index = ownerIndex(owner);

        require(
            index != -1,
            "Ownable: owner does not exists"
        );

        _owners[uint(index)] = _owners[_owners.length -1];
        _owners.pop();
    }

    /// @notice Revoke ownership of contract
    /// @dev Convenience function that just calls
    /// removeOwner(msg.sender)
    function revokeOwnership()
    public
    onlyOwner
    {
        removeOwner(msg.sender);
    }

    /// @notice Transfer ownership of contract
    /// @dev Convenience function that calls addOwner(newOwner)
    /// and then revokeOwnership()
    function transferOwnership(address newOwner)
    public
    onlyOwner
    {
        addOwner(newOwner);
        revokeOwnership();
    }


}
