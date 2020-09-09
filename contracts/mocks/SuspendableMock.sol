// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "../utils/Suspendable.sol";

contract SuspendableMock is Suspendable {

    constructor() {}

    function getState() public view returns (State) {
        return _state;
    }

    function resume() public {
        _resume();
    }

    function suspend() public {
        _suspend();
    }

}