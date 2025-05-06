// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {OnlyFiles} from "../src/client/OnlyFiles.sol";
import {BaseScript} from "./BaseScript.s.sol";
import {ScriptReturns} from "./types/ScriptReturns.sol";

contract DeployOnlyFiles is BaseScript {
    ScriptReturns.DeployOnlyFiles private contracts;

    function run()
        external
        broadcaster
        returns (ScriptReturns.DeployOnlyFiles memory)
    {
        contracts.onlyFiles = new OnlyFiles(getOracle());
        assertions();

        print("OnlyFiles", address(contracts.onlyFiles));
        return contracts;
    }

    function assertions() private {
        require(contracts.onlyFiles.oracle() == getOracle());
    }
}
