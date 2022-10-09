// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {BN254EncryptionOracle} from "../src/BN254EncryptionOracle.sol";
import {Suite} from "../src/OracleFactory.sol";
import {Bn128} from "../src/Bn128.sol";

contract BN254EncryptionOracleTest is Test {
    BN254EncryptionOracle oracle;

    function setUp() public {
        oracle = new BN254EncryptionOracle(Bn128.g1Zero());
    }

    function testSuite() public {
        assert(oracle.suite() == Suite.BN254_KEYG1_HGAMAL);
    }
}
