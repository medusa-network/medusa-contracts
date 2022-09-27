// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {OracleFactory, UnsupportedSuite} from "../src/OracleFactory.sol";
import {Bn128} from "../src/Bn128.sol";

contract OracleFactoryTest is Test {
    OracleFactory factory;

    function setUp() public {
        factory = new OracleFactory();
    }

    function testDeployNewOracle() public {
        (bytes32 oracleId, address oracleAddress) =
            factory.deployNewOracle(Bn128.g1Zero(), OracleFactory.Suite.BN254_KEYG1_HGAMAL);
        assertEq(factory.oracles(oracleId), oracleAddress);

        (bytes32 secondOracleId, address secondOracleAddress) =
            factory.deployNewOracle(Bn128.g1Zero(), OracleFactory.Suite.BN254_KEYG1_HGAMAL);
        assertEq(factory.oracles(secondOracleId), secondOracleAddress);

        assertFalse(oracleId == secondOracleId);
    }

    function testCannotDeployNewOracle() public {
        vm.prank(address(uint160(12345)));
        vm.expectRevert("Ownable: caller is not the owner");
        factory.deployNewOracle(Bn128.g1Zero(), OracleFactory.Suite.BN254_KEYG1_HGAMAL);
    }

    function testCannotDeployNewOracleIfUnsupportedSuite() public {
        // TODO: How to pass unsupported Suite?

        // OracleFactory.Suite suite = OracleFactory.Suite(12345) // Does not compile
        // vm.expectRevert(UnsupportedSuite.selector);
        // (bytes32 oracleId, address oracleAddress) = factory.deployNewOracle(Bn128.g1Zero(), suite);
    }
}
