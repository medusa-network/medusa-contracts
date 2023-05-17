// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {BaseScript} from "./BaseScript.s.sol";
import {DKG} from "../src/DKG.sol";
import {ScriptReturns} from "./types/ScriptReturns.sol";

contract DeployDKG is BaseScript {
    ScriptReturns.DeployDKG private contracts;

    function run()
        external
        broadcaster
        returns (ScriptReturns.DeployDKG memory)
    {
        contracts.dkg = getDKGFactory().deployNewDKG();
        assertions();
        return contracts;
    }

    function assertions() private {
        require(contracts.dkg.membership() == getDKGFactory());
    }
}
