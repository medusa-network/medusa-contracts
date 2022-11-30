// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {EncryptionOracle} from "./EncryptionOracle.sol";
import {G1Point} from "./Bn128.sol";
import {Suite} from "../src/OracleFactory.sol";

contract BN254EncryptionOracle is EncryptionOracle {
    constructor(G1Point memory _distKey, address _relayer) EncryptionOracle(_distKey, _relayer) {}

    function suite() external pure override returns (Suite) {
        return Suite.BN254_KEYG1_HGAMAL;
    }
}
