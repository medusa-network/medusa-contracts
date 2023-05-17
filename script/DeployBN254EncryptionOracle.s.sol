// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.s.sol";
import {BN254EncryptionOracle} from "../src/BN254EncryptionOracle.sol";
import {EncryptionOracle} from "../src/EncryptionOracle.sol";
import {DeployOracleReturn} from "./types/ScriptReturnTypes.sol";

contract DeployBN254EncryptionOracle is BaseScript {
    function run() external returns (DeployOracleReturn memory) {
        address deployer = getDeployer();
        address relayer = getNodes()[0];
        uint96 submissionFee = uint96(vm.envUint("SUBMISSION_FEE"));
        uint96 reencryptionFee = uint96(vm.envUint("REENCRYPTION_FEE"));

        vm.startBroadcast(deployer);

        BN254EncryptionOracle oracleImplementation = new BN254EncryptionOracle();

        address proxy = getOracleFactory().deployDeterministicAndCall(
            address(oracleImplementation),
            deployer,
            bytes32(abi.encodePacked(deployer, "BN254EncryptionOracle_SALT")),
            abi.encodeWithSignature(
                "initialize((uint256,uint256),address,address,uint96,uint96)",
                getDistributedKey(),
                deployer,
                relayer,
                submissionFee,
                reencryptionFee
            )
        );

        vm.stopBroadcast();
        return DeployOracleReturn(oracleImplementation, EncryptionOracle(proxy));
    }
}
