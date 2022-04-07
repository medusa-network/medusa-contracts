// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "./EncryptionOracle.sol";
import "./Bn128.sol";

contract TestContract is EncryptionOracle {
    uint256 private value;
    function setValue(uint256 _value) public {
        value = _value;
    }

    // used to quickly setup a dist key without going through the whole DKG
    // onchain
    function setDistributedKey(uint256 _point) public onlyOwner {
        Bn128.G1Point memory key = Bn128.g1Decompress(bytes32(_point));
        dist_key = key;
    }
}
