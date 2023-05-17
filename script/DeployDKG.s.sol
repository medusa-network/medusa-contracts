// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {BaseScript} from "./BaseScript.s.sol";
import {DKG} from "../src/DKG.sol";
import {DeployDKGReturn} from "./types/ScriptReturnTypes.sol";

contract DeployDKG is BaseScript {
    function run() external returns (DeployDKGReturn memory) {
        vm.startBroadcast(getDeployer());

        DKG dkg = getDKGFactory().deployNewDKG();

        vm.stopBroadcast();
        return DeployDKGReturn(dkg);
    }
}
