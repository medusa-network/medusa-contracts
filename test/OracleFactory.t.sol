// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {OracleFactory, Suite, UnsupportedSuite} from "../src/OracleFactory.sol";
import {EncryptionOracle} from "../src/EncryptionOracle.sol";
import {Bn128, G1Point} from "../src/Bn128.sol";

contract OracleFactoryTest is Test {
    OracleFactory private factory;

    function setUp() public {
        factory = new OracleFactory();
    }

    function testDeployNewOracle() public {
        address oracleAddress = factory.deployNewOracle(Bn128.g1Zero(), Suite.BN254_KEYG1_HGAMAL);
        assertEq(factory.oracles(oracleAddress), true);

        address secondOracleAddress =
            factory.deployNewOracle(Bn128.g1Zero(), Suite.BN254_KEYG1_HGAMAL);
        assertEq(factory.oracles(secondOracleAddress), true);

        assertFalse(oracleAddress == secondOracleAddress);
    }

    function testCannotDeployNewOracle() public {
        vm.prank(address(uint160(12345)));
        vm.expectRevert("Ownable: caller is not the owner");
        factory.deployNewOracle(Bn128.g1Zero(), Suite.BN254_KEYG1_HGAMAL);
    }

    function testCannotDeployNewOracleIfUnsupportedSuite() public {
        bytes4 deployNewOracleSelector = factory.deployNewOracle.selector;
        G1Point memory pubkey = Bn128.g1Zero();
        uint256 unsupportedSuite = 1;
        address factoryAddress = address(factory);

        // NOTE: We have to use assembly because constructing an Unsupported Suite is a compile-error in Solidity
        // Copied from Solmate SafeTransferLib
        // https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol#L38
        bool success;
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, deployNewOracleSelector)
            mstore(add(freeMemoryPointer, 4), pubkey) // Append the "_distKey" argument (64 bytes).
            mstore(add(freeMemoryPointer, 68), unsupportedSuite) // Append the "_suite" argument (32 bytes).

            // We use 0 because we are not sending any Ether.
            // We use 100 because the length of our calldata totals up like so: 4 + 64 + 32.
            // We use 0 and 0 because we copy 0 return data into 0 scratch space.
            success := call(gas(), factoryAddress, 0, freeMemoryPointer, 100, 0, 0)
        }
        assertFalse(success);
    }

    function testPauseOracle() public {
        address oracleAddress = factory.deployNewOracle(Bn128.g1Zero(), Suite.BN254_KEYG1_HGAMAL);

        assertFalse(EncryptionOracle(oracleAddress).paused());
        factory.pauseOracle(oracleAddress);
        assertTrue(EncryptionOracle(oracleAddress).paused());
    }

    function testCannotPauseOracleIfNotOwner() public {
        address oracleAddress = factory.deployNewOracle(Bn128.g1Zero(), Suite.BN254_KEYG1_HGAMAL);

        assertFalse(EncryptionOracle(oracleAddress).paused());
        address notOwner = makeAddr("notOwner");
        vm.expectRevert("Ownable: caller is not the owner");
        hoax(notOwner);
        factory.pauseOracle(oracleAddress);
        assertFalse(EncryptionOracle(oracleAddress).paused());
    }

    function testUnpauseOracle() public {
        address oracleAddress = factory.deployNewOracle(Bn128.g1Zero(), Suite.BN254_KEYG1_HGAMAL);

        factory.pauseOracle(oracleAddress);
        assertTrue(EncryptionOracle(oracleAddress).paused());
        factory.unpauseOracle(oracleAddress);
        assertFalse(EncryptionOracle(oracleAddress).paused());
    }

    function testCannotUnpauseOracleIfNotOwner() public {
        address oracleAddress = factory.deployNewOracle(Bn128.g1Zero(), Suite.BN254_KEYG1_HGAMAL);

        factory.pauseOracle(oracleAddress);
        assertTrue(EncryptionOracle(oracleAddress).paused());
        address notOwner = makeAddr("notOwner");
        vm.expectRevert("Ownable: caller is not the owner");
        hoax(notOwner);
        factory.unpauseOracle(oracleAddress);
        assertTrue(EncryptionOracle(oracleAddress).paused());
    }
}
