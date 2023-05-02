// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../src/DKGFactory.sol";
import {BaseScript} from "./BaseScript.s.sol";

contract AddAuthorizedNodes is BaseScript {
    using Strings for uint256;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DKGFactory factory = DKGFactory(getDKGFactoryAddress());

        for (uint256 i = 1; i <= 3; i++) {
            address node = vm.envAddress(
                string(abi.encodePacked("NODE_", i.toString(), "_ADDRESS"))
            );
            if (!factory.isAuthorizedNode(node)) {
                factory.addAuthorizedNode(node);
            }
        }

        vm.stopBroadcast();
    }
}
