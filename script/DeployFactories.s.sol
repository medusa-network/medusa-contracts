// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {BaseScript} from "./BaseScript.s.sol";
import {OracleFactory} from "../src/OracleFactory.sol";
import {DKGManager} from "../src/DKGManager.sol";
import {ScriptReturns} from "./types/ScriptReturns.sol";

contract DeployFactories is BaseScript {
    ScriptReturns.DeployFactories private contracts;

    function run()
        external
        broadcaster
        returns (ScriptReturns.DeployFactories memory)
    {
        contracts.dkgManager = new DKGManager{salt: salt}(deployer);
        contracts.oracleFactory = new OracleFactory{salt: salt}(deployer);

        assertions();
        return contracts;
    }

    function assertions() private view {
        require(contracts.dkgManager.owner() == deployer);
        require(contracts.oracleFactory.owner() == deployer);
    }
}
