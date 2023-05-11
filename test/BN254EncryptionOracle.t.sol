// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {BN254EncryptionOracle} from "../src/BN254EncryptionOracle.sol";
import {Suite} from "../src/OracleFactory.sol";
import {Bn128} from "../src/Bn128.sol";

contract BN254EncryptionOracleTest is Test {
    BN254EncryptionOracle public oracle;

    function setUp() public {
        oracle = new BN254EncryptionOracle(Bn128.g1Zero(), address(0), 0, 0);
    }

    function testSuite() public view {
        assert(oracle.suite() == Suite.BN254_KEYG1_HGAMAL);
    }
}
