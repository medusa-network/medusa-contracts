// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Bn128, G1Point} from "../src/utils/Bn128.sol";
import {DKG} from "../src/DKG.sol";
import {OracleFactory} from "../src/OracleFactory.sol";
import {DKGFactory} from "../src/DKGFactory.sol";
import {EncryptionOracle} from "../src/EncryptionOracle.sol";

abstract contract BaseScript is Script {
    using Strings for uint256;
    using stdJson for string;

    /// @dev The address of the contract deployer.
    address public deployer;

    // @dev The salt used for deterministic deployment addresses with CREATE2
    bytes32 internal salt;

    modifier broadcaster() {
        vm.startBroadcast(deployer);
        _;
        vm.stopBroadcast();
    }

    constructor() {
        deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        salt = bytes32(abi.encodePacked(deployer, "MEDUSA_V0"));
    }

    function setDeployer(address _deployer) public {
        deployer = _deployer;
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

    function getNodes() internal returns (address[] memory) {
        address[] memory nodes = new address[](3);

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
        uint32 size;
        DKG dkg = getDKG();

        // Check if DKG is deployed
        assembly {
            size := extcodesize(dkg)
        }

        if (size > 0) return dkg.distributedKey();
        else return Bn128.g1Zero();
    }
}
