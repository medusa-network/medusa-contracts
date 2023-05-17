// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {OnlyFiles} from "../src/client/OnlyFiles.sol";
import {BaseScript} from "./BaseScript.s.sol";

contract DeployOnlyFiles is BaseScript {
    function run() external {
        vm.startBroadcast(getDeployer());

        new OnlyFiles(getOracle());

        vm.stopBroadcast();
    }
}
