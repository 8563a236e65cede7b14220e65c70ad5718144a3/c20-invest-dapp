// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

/// @title Suspendable Base Contract
/// @author Invictus Capital
/// @notice Helper contract for suspend/resume functionality
/// @dev Contract module that allows control flow based on
/// whether the contract is in the Active state or in the
/// Suspended state.
///
/// The modifiers onlyActive and onlySuspended
/// are used to signal functions that can only be run in the
/// Active and Suspended states respectively.
///
/// The state of the contract can be controlled
/// with the _suspend() and _resume() functions.
contract Suspendable {
    /// @dev An enumeration for the state of the contract.
    enum State { Active, Suspended }

    /// @dev The stored internal state of the contract.
    State internal _state;

    /// @dev Emitted when the contract is suspended.
    /// Logs the account which changed the state.
    event Suspended(address account);

    /// @dev Emitted when the contract is resumed.
    /// Logs the account which changed the state.
    event Resumed(address account);

    /// @dev Sets the contract state to active upon
    /// construction.
    constructor () {
        _state = State.Active;
    }

    /// @dev The function that suspends the contract. It
    /// is internal and so only can be used within smart
    /// contracts that inherit from it, and not called
    /// from the outside. The contract that inherits from
    /// it will need to make their own wrapper that calls
    /// this function and possibly protect ownership with
    /// an onlyOwner modifier or similar method.
    function _suspend() internal onlyActive {
        _state = State.Suspended;
        emit Suspended(msg.sender);
    }

    /// @dev The function that resumes the contract. It
    /// is internal and so only can be used within smart
    /// contracts that inherit from it, and not called
    /// from the outside. The contract that inherits from
    /// it will need to make their own wrapper that calls
    /// this function and possibly protect ownership with
    /// an onlyOwner modifier or similar method.
    function _resume() internal onlySuspended {
        _state = State.Active;
        emit Resumed(msg.sender);
    }

    /// @dev Modifier to mark functions that can only be
    /// called when the contract is in the Active state
    modifier onlyActive() {
        require(
            _state == State.Active,
            "Suspendable: function only available while contract active"
        );
        _;
    }

    /// @dev Modifier to mark functions that can only be
    /// called when the contract is in the Suspended state
    modifier onlySuspended() {
        require(
            _state == State.Suspended,
            "Suspendable: function only available while contract suspended"
        );
        _;
    }

}