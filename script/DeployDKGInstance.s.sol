// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../src/DKGFactory.sol";
import {BaseScript} from "./BaseScript.s.sol";

contract DeployDKGInstance is BaseScript {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DKGFactory factory = DKGFactory(getDKGFactoryAddress());
        factory.deployNewDKG();

        vm.stopBroadcast();
    }
}
