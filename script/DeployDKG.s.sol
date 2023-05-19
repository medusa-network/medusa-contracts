// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {BaseScript} from "./BaseScript.s.sol";
import {PermissionedDKGMembership} from "../src/PermissionedDKGMembership.sol";
import {DKG} from "../src/DKG.sol";
import {ScriptReturns} from "./types/ScriptReturns.sol";

contract DeployDKG is BaseScript {
    ScriptReturns.DeployDKG private contracts;
    address[] private nodes = getNodes();

    function run()
        external
        broadcaster
        returns (ScriptReturns.DeployDKG memory)
    {
        contracts.dkgMembership =
            new PermissionedDKGMembership{salt: salt}(deployer);

        for (uint256 i = 0; i < nodes.length; i++) {
            if (nodes[i] != address(0)) {
                contracts.dkgMembership.addAuthorizedNode(nodes[i]);
            }
        }

        contracts.nodes = nodes;
        contracts.dkg = new DKG{salt: salt}(contracts.dkgMembership);
        getDKGManager().registerNewDKG(contracts.dkg);

        assertions();
        return contracts;
    }

    function assertions() private view {
        require(contracts.dkg.membership() == contracts.dkgMembership);

        for (uint256 i = 0; i < nodes.length; i++) {
            if (nodes[i] != address(0)) {
                require(contracts.dkgMembership.isAuthorizedNode(nodes[i]));
            }
        }
    }
}
