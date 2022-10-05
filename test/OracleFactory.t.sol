// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {OracleFactory} from "../src/OracleFactory.sol";
import {EncryptionOracle} from "../src/EncryptionOracle.sol";
import {Bn128, G1Point} from "../src/Bn128.sol";

contract OracleFactoryTest is Test {
    OracleFactory private factory;

    function setUp() public {
        factory = new OracleFactory();
    }

    function testDeployNewOracle() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(Bn128.g1Zero());
        assertEq(factory.oracles(oracleAddress), true);

        address secondOracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(Bn128.g1Zero());
        assertEq(factory.oracles(secondOracleAddress), true);

        assertFalse(oracleAddress == secondOracleAddress);
    }

    function testCannotDeployNewOracle() public {
        vm.prank(address(uint160(12345)));
        vm.expectRevert("Ownable: caller is not the owner");
        factory.deployReencryption_BN254_G1_HGAMAL(Bn128.g1Zero());
    }

    function testPauseOracle() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(Bn128.g1Zero());

        assertFalse(EncryptionOracle(oracleAddress).paused());
        factory.pauseOracle(oracleAddress);
        assertTrue(EncryptionOracle(oracleAddress).paused());
    }

    function testCannotPauseOracleIfNotOwner() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(Bn128.g1Zero());

        assertFalse(EncryptionOracle(oracleAddress).paused());
        address notOwner = makeAddr("notOwner");
        vm.expectRevert("Ownable: caller is not the owner");
        hoax(notOwner);
        factory.pauseOracle(oracleAddress);
        assertFalse(EncryptionOracle(oracleAddress).paused());
    }

    function testUnpauseOracle() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(Bn128.g1Zero());

        factory.pauseOracle(oracleAddress);
        assertTrue(EncryptionOracle(oracleAddress).paused());
        factory.unpauseOracle(oracleAddress);
        assertFalse(EncryptionOracle(oracleAddress).paused());
    }

    function testCannotUnpauseOracleIfNotOwner() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(Bn128.g1Zero());

        factory.pauseOracle(oracleAddress);
        assertTrue(EncryptionOracle(oracleAddress).paused());
        address notOwner = makeAddr("notOwner");
        vm.expectRevert("Ownable: caller is not the owner");
        hoax(notOwner);
        factory.unpauseOracle(oracleAddress);
        assertTrue(EncryptionOracle(oracleAddress).paused());
    }
}
