// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

contract TestContract {
    uint256 private value;
    function setValue(uint256 _value) public {
        value = _value;
    }
}
