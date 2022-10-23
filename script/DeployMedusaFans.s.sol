// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/MedusaFans.sol";
import {BaseScript} from "./BaseScript.s.sol";
import {BN254EncryptionOracle as Oracle} from "../src/BN254EncryptionOracle.sol";

contract DeployMedusaFans is BaseScript {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        new MedusaFans(Oracle(getOracleInstanceAddress()));
        vm.stopBroadcast();
    }
}
