// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {OracleFactory} from "../src/OracleFactory.sol";
import {ERC1967Factory} from "solady/utils/ERC1967Factory.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {
    EncryptionOracle, NotRelayerOrOwner
} from "../src/EncryptionOracle.sol";
import {BN254EncryptionOracle} from "../src/BN254EncryptionOracle.sol";
import {Bn128, G1Point} from "../src/utils/Bn128.sol";
import {DeployFactories} from "../script/DeployFactories.s.sol";

contract OracleFactoryTest is Test {
    OracleFactory private factory;
    EncryptionOracle private oracleImplementation;
    EncryptionOracle private oracle;

    address private owner = address(this);
    address private notOwner = makeAddr("notOwner");
    address private relayer = makeAddr("relayer");

    uint8 private deploymentCounter;

    event NewOracleDeployed(address oracle);

    function setUp() public {
        oracleImplementation = new BN254EncryptionOracle();

        factory = new DeployFactories().run().oracleFactory;
        vm.prank(factory.owner());
        factory.transferOwnership(owner);

        oracle = deployOracle(owner);
    }

    function salt(address caller) private view returns (bytes32) {
        return bytes32(abi.encodePacked(caller, deploymentCounter));
    }

    function deployOracle(address caller) private returns (EncryptionOracle) {
        deploymentCounter += 1;
        address proxy = factory.deployDeterministicAndCall(
            address(oracleImplementation),
            caller,
            salt(caller),
            abi.encodeWithSignature(
                "initialize((uint256,uint256),address,address,uint96,uint96)",
                Bn128.g1Zero(),
                caller,
                relayer,
                0,
                0
            )
        );
        return EncryptionOracle(proxy);
    }

    function testDeployNewOracle() public {
        address proxy = factory.predictDeterministicAddress(salt(owner));
        vm.expectEmit(true, true, false, false);
        emit NewOracleDeployed(proxy);
        deployOracle(owner);
    }

    function testCannotDeployNewOracleIfNotOwner() public {
        vm.prank(notOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        deployOracle(notOwner);
    }
}
