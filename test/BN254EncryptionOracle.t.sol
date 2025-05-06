// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {MedusaTest} from "./MedusaTest.sol";
import {BN254EncryptionOracle} from "../src/BN254EncryptionOracle.sol";
import {Suite} from "../src/interfaces/IEncryptionOracle.sol";
import {Bn128} from "../src/utils/Bn128.sol";

contract BN254EncryptionOracleTest is MedusaTest {
    BN254EncryptionOracle public oracle;

    function setUp() public {
        oracle = new BN254EncryptionOracle();
        oracle.initialize(Bn128.g1Zero(), address(this), address(0), 0, 0);
    }

    function testSuite() public view {
        assert(oracle.suite() == Suite.BN254_KEYG1_HGAMAL);
    }
}
