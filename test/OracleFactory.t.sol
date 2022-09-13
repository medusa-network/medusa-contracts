// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "ds-test/test.sol";
import "../src/OracleFactory.sol";

contract OracleFactoryTest is DSTest {
    OracleFactory oracle;

    function setUp() public {
        oracle = new OracleFactory();
    }

    function testFactoryStart() public {
        address a1 = oracle.startNewOracle();
        address a2 = oracle.startNewOracle();
    }
}
