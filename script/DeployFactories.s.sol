// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {BaseScript} from "./BaseScript.s.sol";
import {OracleFactory} from "../src/OracleFactory.sol";
import {DKGFactory} from "../src/DKGFactory.sol";
import {DeployFactoriesReturn} from "./types/ScriptReturnTypes.sol";

contract DeployFactories is BaseScript {
    function run() external returns (DeployFactoriesReturn memory) {
        vm.startBroadcast(getDeployer());

        DKGFactory dkgFactory = new DKGFactory();
        OracleFactory oracleFactory = new OracleFactory();
        address[3] memory nodes = addAuthorizedNodes(dkgFactory);

        vm.stopBroadcast();
        return DeployFactoriesReturn(dkgFactory, oracleFactory, nodes);
    }

    function addAuthorizedNodes(DKGFactory dkgFactory)
        private
        returns (address[3] memory nodes)
    {
        nodes = getNodes();

        for (uint256 i = 0; i < nodes.length; i++) {
            dkgFactory.addAuthorizedNode(nodes[i]);
        }

        return nodes;
    }
}
