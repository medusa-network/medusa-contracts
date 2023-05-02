// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract BaseScript is Script {
    using Strings for uint256;
    using stdJson for string;

    function getOracleFactoryAddress() internal returns (address) {
        return vm.envAddress("ORACLE_FACTORY_ADDRESS");
    }

    function getDKGFactoryAddress() internal returns (address) {
        return vm.envAddress("DKG_FACTORY_ADDRESS");
    }

    function getOracleInstanceAddress() internal returns (address) {
        return vm.envAddress("ORACLE_ADDRESS");
    }

    function getDKGInstanceAddress() internal returns (address) {
        return vm.envAddress("DKG_ADDRESS");
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
