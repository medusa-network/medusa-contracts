// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/OnlyFiles.sol";
import {BaseScript} from "./BaseScript.s.sol";
import {BN254EncryptionOracle as Oracle} from "../src/BN254EncryptionOracle.sol";

contract DeployOnlyFiles is BaseScript {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        new OnlyFiles(Oracle(getOracleInstanceAddress()));
        vm.stopBroadcast();
    }
}
