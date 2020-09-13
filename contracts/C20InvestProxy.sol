// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./proxy/TransparentUpgradeableProxy.sol";
import "./access/Ownable.sol";

contract C20InvestProxy is TransparentUpgradeableProxy, Ownable {

    /// @dev Constructor to pass constructor arguments to base
    /// classes
    constructor(address[] memory owners) Ownable(owners) {

    }
}


