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
        bytes4 deployNewOracleSelector = factory.deployNewOracle.selector;
        Bn128.G1Point memory pubkey = Bn128.g1Zero();
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

            success
            // We use 100 because the length of our calldata totals up like so: 4 + 64 + 32.
            // We use 0 and 0 because we don't need to copy the return data into the scratch space.
            := call(gas(), factoryAddress, 0, freeMemoryPointer, 100, 0, 0)
        }
        assertFalse(success);
    }
}
