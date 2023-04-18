// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {OracleFactory} from "../src/OracleFactory.sol";

contract DeployOracleFactory is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        new OracleFactory();
        vm.stopBroadcast();
    }
}
