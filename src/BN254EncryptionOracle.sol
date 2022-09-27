// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {EncryptionOracle} from "./EncryptionOracle.sol";
import {OracleFactory} from "./OracleFactory.sol";
import "./Bn128.sol";

contract BN254EncryptionOracle is EncryptionOracle {
    constructor(Bn128.G1Point memory _distKey) EncryptionOracle(_distKey) {}

    function suite() external pure override returns (OracleFactory.Suite) {
        return OracleFactory.Suite.BN254_KEYG1_HGAMAL;
    }
}
