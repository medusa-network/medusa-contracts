// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {OracleFactory} from "../src/OracleFactory.sol";
import {DKG} from "../src/DKG.sol";
import {G1Point} from "../src/Bn128.sol";
import {BaseScript} from "./BaseScript.s.sol";

contract DeployBN254EncryptionOracle is BaseScript {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address relayer = vm.envAddress("NODE_1_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        OracleFactory factory = OracleFactory(getOracleFactoryAddress());
        factory.deployReencryption_BN254_G1_HGAMAL(getDistributedKey(), relayer);
        vm.stopBroadcast();
    }

    function getDistributedKey() private returns (G1Point memory) {
        DKG dkg = DKG(getDKGInstanceAddress());
        return dkg.distributedKey();
    }
}
