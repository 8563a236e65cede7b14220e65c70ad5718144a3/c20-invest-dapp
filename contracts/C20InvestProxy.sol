// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./proxy/TransparentUpgradeableProxy.sol";
import "./access/Ownable.sol";

contract C20InvestProxy is TransparentUpgradeableProxy {

    /// @dev Constructor to pass constructor arguments to base
    /// classes
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_logic, _admin, _data) {

    }


}


