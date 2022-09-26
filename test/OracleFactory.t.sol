// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "ds-test/test.sol";
import {OracleFactory} from "../src/OracleFactory.sol";
import {Bn128} from "../src/Bn128.sol";

contract OracleFactoryTest is DSTest {
    OracleFactory oracle;

    function setUp() public {
        oracle = new OracleFactory();
    }

    function testFactoryStart() public {
        oracle.startNewOracle(Bn128.g1Zero());
        oracle.startNewOracle(Bn128.g1Zero());
    }
}
