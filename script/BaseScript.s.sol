// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {G1Point} from "../src/utils/Bn128.sol";
import {DKG} from "../src/DKG.sol";
import {OracleFactory} from "../src/OracleFactory.sol";
import {DKGFactory} from "../src/DKGFactory.sol";
import {EncryptionOracle} from "../src/EncryptionOracle.sol";

abstract contract BaseScript is Script {
    using Strings for uint256;
    using stdJson for string;

    function getDeployer() internal returns (address) {
        return vm.rememberKey(vm.envUint("PRIVATE_KEY"));
    }

    function getOracleFactory() internal returns (OracleFactory) {
        return OracleFactory(vm.envAddress("ORACLE_FACTORY_ADDRESS"));
    }

    function getDKGFactory() internal returns (DKGFactory) {
        return DKGFactory(vm.envAddress("DKG_FACTORY_ADDRESS"));
    }

    function getOracle() internal returns (EncryptionOracle) {
        return EncryptionOracle(vm.envAddress("ORACLE_ADDRESS"));
    }

    function getDKG() internal returns (DKG) {
        return DKG(vm.envAddress("DKG_ADDRESS"));
    }

    function getNodes() internal returns (address[3] memory nodes) {
        for (uint256 i = 0; i < nodes.length; i++) {
            address node = vm.envAddress(
                string(
                    abi.encodePacked("NODE_", (i + 1).toString(), "_ADDRESS")
                )
            );
            nodes[i] = node;
        }

        return nodes;
    }

    function getDistributedKey() internal returns (G1Point memory) {
        return getDKG().distributedKey();
    }

    function getOracleFactoryAddressFromBroadcast()
        internal
        returns (address)
    {
        string memory filename = string(
            abi.encodePacked(
                "broadcast/DeployOracleFactory.s.sol/",
                block.chainid.toString(),
                "/run-latest.json"
            )
        );
        string memory json = vm.readFile(filename);
        address factoryAddr =
            json.readAddress(".transactions[0].contractAddress");
        return factoryAddr;
    }

    function getDKGFactoryAddressFromBroadcast() internal returns (address) {
        string memory filename = string(
            abi.encodePacked(
                "broadcast/DeployDKGFactory.s.sol/",
                block.chainid.toString(),
                "/run-latest.json"
            )
        );
        string memory json = vm.readFile(filename);
        address factoryAddr =
            json.readAddress(".transactions[0].contractAddress");
        return factoryAddr;
    }

    function getDKGInstanceAddressFromBroadcast() internal returns (address) {
        string memory filename = string(
            abi.encodePacked(
                "broadcast/DeployDKGInstance.s.sol/",
                block.chainid.toString(),
                "/run-latest.json"
            )
        );
        string memory json = vm.readFile(filename);
        address factoryAddr =
            json.readAddress(".transactions[0].additionalContracts[0].address");
        return factoryAddr;
    }
}
