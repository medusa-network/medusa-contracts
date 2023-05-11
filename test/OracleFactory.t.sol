// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {OracleFactory} from "../src/OracleFactory.sol";
import {EncryptionOracle} from "../src/EncryptionOracle.sol";
import {Bn128, G1Point} from "../src/Bn128.sol";

contract OracleFactoryTest is Test {
    OracleFactory private factory;
    address relayer = makeAddr("relayer");

    function setUp() public {
        factory = new OracleFactory();
    }

    function testDeployNewOracle() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(
            Bn128.g1Zero(), relayer, 0, 0
        );
        assertEq(factory.oracles(oracleAddress), true);

        address secondOracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(
            Bn128.g1Zero(), relayer, 0, 0
        );
        assertEq(factory.oracles(secondOracleAddress), true);

        assertFalse(oracleAddress == secondOracleAddress);
    }

    function testCannotDeployNewOracle() public {
        vm.prank(address(uint160(12345)));
        vm.expectRevert("Ownable: caller is not the owner");
        factory.deployReencryption_BN254_G1_HGAMAL(
            Bn128.g1Zero(), relayer, 0, 0
        );
    }

    function testPauseOracle() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(
            Bn128.g1Zero(), relayer, 0, 0
        );

        assertFalse(EncryptionOracle(oracleAddress).paused());
        factory.pauseOracle(oracleAddress);
        assertTrue(EncryptionOracle(oracleAddress).paused());
    }

    function testCannotPauseOracleIfNotOwner() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(
            Bn128.g1Zero(), relayer, 0, 0
        );

        assertFalse(EncryptionOracle(oracleAddress).paused());
        address notOwner = makeAddr("notOwner");
        vm.expectRevert("Ownable: caller is not the owner");
        hoax(notOwner);
        factory.pauseOracle(oracleAddress);
        assertFalse(EncryptionOracle(oracleAddress).paused());
    }

    function testUnpauseOracle() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(
            Bn128.g1Zero(), relayer, 0, 0
        );

        factory.pauseOracle(oracleAddress);
        assertTrue(EncryptionOracle(oracleAddress).paused());
        factory.unpauseOracle(oracleAddress);
        assertFalse(EncryptionOracle(oracleAddress).paused());
    }

    function testCannotUnpauseOracleIfNotOwner() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(
            Bn128.g1Zero(), relayer, 0, 0
        );

        factory.pauseOracle(oracleAddress);
        assertTrue(EncryptionOracle(oracleAddress).paused());
        address notOwner = makeAddr("notOwner");
        vm.expectRevert("Ownable: caller is not the owner");
        hoax(notOwner);
        factory.unpauseOracle(oracleAddress);
        assertTrue(EncryptionOracle(oracleAddress).paused());
    }

    function testUpdateRelayer() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(
            Bn128.g1Zero(), relayer, 0, 0
        );
        address newRelayer = makeAddr("newRelayer");

        factory.updateRelayer(oracleAddress, newRelayer);
        assert(EncryptionOracle(oracleAddress).relayer() == newRelayer);
    }

    function testCannotUpdateRelayerIfNotOwner() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(
            Bn128.g1Zero(), relayer, 0, 0
        );
        address notOwner = makeAddr("notOwner");
        address newRelayer = makeAddr("newRelayer");

        vm.expectRevert("Ownable: caller is not the owner");
        hoax(notOwner);
        factory.updateRelayer(oracleAddress, newRelayer);
        assert(EncryptionOracle(oracleAddress).relayer() == relayer);
    }

    function testUpdateSubmissionFee() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(
            Bn128.g1Zero(), relayer, 0, 0
        );

        factory.updateSubmissionFee(oracleAddress, 1);
        assert(EncryptionOracle(oracleAddress).submissionFee() == 1);
    }

    function testCannotUpdateSubmissionFeeIfNotOwner() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(
            Bn128.g1Zero(), relayer, 0, 0
        );
        address notOwner = makeAddr("notOwner");

        vm.expectRevert("Ownable: caller is not the owner");
        hoax(notOwner);
        factory.updateSubmissionFee(oracleAddress, 1);
        assert(EncryptionOracle(oracleAddress).submissionFee() == 0);
    }

    function testUpdateReencryptionFee() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(
            Bn128.g1Zero(), relayer, 0, 0
        );

        factory.updateReencryptionFee(oracleAddress, 1);
        assert(EncryptionOracle(oracleAddress).reencryptionFee() == 1);
    }

    function testCannotUpdateReencryptionFeeIfNotOwner() public {
        address oracleAddress = factory.deployReencryption_BN254_G1_HGAMAL(
            Bn128.g1Zero(), relayer, 0, 0
        );
        address notOwner = makeAddr("notOwner");

        vm.expectRevert("Ownable: caller is not the owner");
        hoax(notOwner);
        factory.updateReencryptionFee(oracleAddress, 1);
        assert(EncryptionOracle(oracleAddress).reencryptionFee() == 0);
    }
}
