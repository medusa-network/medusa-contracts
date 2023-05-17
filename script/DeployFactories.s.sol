// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {BaseScript} from "./BaseScript.s.sol";
import {OracleFactory} from "../src/OracleFactory.sol";
import {DKGFactory} from "../src/DKGFactory.sol";
import {ScriptReturns} from "./types/ScriptReturns.sol";

contract DeployFactories is BaseScript {
    address[] private nodes = getNodes();
    ScriptReturns.DeployFactories private contracts;

    function run()
        external
        broadcaster
        returns (ScriptReturns.DeployFactories memory)
    {
        contracts.dkgFactory = new DKGFactory{salt: salt}(deployer);
        contracts.oracleFactory = new OracleFactory{salt: salt}(deployer);

        for (uint256 i = 0; i < nodes.length; i++) {
            contracts.dkgFactory.addAuthorizedNode(nodes[i]);
        }
        contracts.nodes = nodes;
        assertions();
        return contracts;
    }

    function assertions() private view {
        require(contracts.dkgFactory.owner() == deployer);
        require(contracts.oracleFactory.owner() == deployer);

        for (uint256 i = 0; i < nodes.length; i++) {
            require(contracts.dkgFactory.isAuthorizedNode(nodes[i]));
        }
    }
}
