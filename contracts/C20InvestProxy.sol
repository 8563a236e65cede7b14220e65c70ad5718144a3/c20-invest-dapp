// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./proxy/TransparentUpgradeableProxy.sol";

contract C20InvestProxy is TransparentUpgradeableProxy {

    /// @dev Pass constructor arguments to base
    /// class
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, _admin, _data) {

    }

}


