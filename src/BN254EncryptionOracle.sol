// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {Suite} from "../src/interfaces/IEncryptionOracle.sol";
import {EncryptionOracle} from "./EncryptionOracle.sol";
import {G1Point} from "./Bn128.sol";

contract BN254EncryptionOracle is EncryptionOracle {
    constructor(G1Point memory _distKey, address _relayer, uint96 _oracleFee)
        EncryptionOracle(_distKey, _relayer, _oracleFee)
    {}

    function suite() external pure override returns (Suite) {
        return Suite.BN254_KEYG1_HGAMAL;
    }
}
