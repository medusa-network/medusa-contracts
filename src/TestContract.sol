// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "./EncryptionOracle.sol";

contract TestContract is EncryptionOracle {
    uint256 private value;
    function setValue(uint256 _value) public {
        value = _value;
    }
}
