// SPDX-License-Identifier: MIT

pragma solidity =0.7.0;

import "../math/SafeMathNew.sol";

contract SafeMathMock {
    function mul(uint256 a, uint256 b) public pure returns (uint256) {
        return SafeMathNew.mul(a, b);
    }

    function div(uint256 a, uint256 b) public pure returns (uint256) {
        return SafeMathNew.div(a, b);
    }

    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        return SafeMathNew.sub(a, b);
    }

    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return SafeMathNew.add(a, b);
    }

    function mod(uint256 a, uint256 b) public pure returns (uint256) {
        return SafeMathNew.mod(a, b);
    }
}
