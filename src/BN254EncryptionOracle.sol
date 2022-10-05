// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {EncryptionOracle} from "./EncryptionOracle.sol";
import {G1Point} from "./Bn128.sol";

contract BN254EncryptionOracle is EncryptionOracle {
    constructor(G1Point memory _distKey) EncryptionOracle(_distKey) {}
}
