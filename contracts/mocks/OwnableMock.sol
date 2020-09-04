// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "../access/Ownable.sol";

contract OwnableMock is Ownable {

    constructor(address[] memory owners) Ownable(owners) {

    }

}