// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {MedusaTest} from "./MedusaTest.sol";
import {OracleFactory} from "../src/OracleFactory.sol";
import {ERC1967Factory} from "solady/utils/ERC1967Factory.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {
    EncryptionOracle, NotRelayerOrOwner
} from "../src/EncryptionOracle.sol";
import {BN254EncryptionOracle} from "../src/BN254EncryptionOracle.sol";
import {Bn128, G1Point} from "../src/utils/Bn128.sol";
import {DeployFactories} from "../script/DeployFactories.s.sol";
import {DeployBN254EncryptionOracle} from
    "../script/DeployBN254EncryptionOracle.s.sol";

contract OracleFactoryTest is MedusaTest {
    DeployFactories private factoryDeployerScript;
    DeployBN254EncryptionOracle private oracleDeployerScript;
    uint8 private deploymentCounter;

    OracleFactory private factory;
    EncryptionOracle private oracle;

    event NewOracleDeployed(address oracle);

    function setUp() public {
        factoryDeployerScript = new DeployFactories();
        oracleDeployerScript = new DeployBN254EncryptionOracle();

        factory = factoryDeployerScript.run().oracleFactory;
    }

    function salt(address caller, uint8 counter)
        private
        pure
        returns (bytes32)
    {
        return bytes32(abi.encodePacked(caller, counter));
    }

    function deployOracle(bytes32 _salt) private returns (EncryptionOracle) {
        deploymentCounter += 1;

        EncryptionOracle _oracle =
            oracleDeployerScript.deploy(factory, _salt).oracle;
        return _oracle;
    }

    function testDeployNewOracle() public {
        bytes32 _salt = salt(
            address(oracleDeployerScript.deployer()), deploymentCounter + 1
        );
        address proxy = factory.predictDeterministicAddress(_salt);
        vm.expectEmit(true, true, false, false);
        emit NewOracleDeployed(proxy);
        deployOracle(_salt);
    }

    function testCannotDeployNewOracleIfNotOwner() public {
        oracleDeployerScript.setDeployer(notOwner);
        bytes32 _salt =
            salt(address(oracleDeployerScript.deployer()), deploymentCounter);

        vm.expectRevert(Ownable.Unauthorized.selector);
        deployOracle(_salt);
    }
}
