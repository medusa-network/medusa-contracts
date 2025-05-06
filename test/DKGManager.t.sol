// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {MedusaTest} from "./MedusaTest.sol";
import {DKGManager} from "../src/DKGManager.sol";
import {DKG} from "../src/DKG.sol";
import {IDKGMembership} from "../src/interfaces/IDKGMembership.sol";
import {DeployFactories} from "../script/DeployFactories.s.sol";
import {DeployDKG} from "../script/DeployDKG.s.sol";
import {ScriptReturns} from "../script/types/ScriptReturns.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract DKGManagerTest is MedusaTest {
    DKGManager private manager;
    DKG private dkg;
    IDKGMembership private membership;

    event NewDKGCreated(address dkg);

    function setUp() public {
        manager = new DeployFactories().run().dkgManager;
        vm.setEnv("DKG_MANAGER_ADDRESS", vm.toString(address(manager)));
        ScriptReturns.DeployDKG memory contracts = new DeployDKG().run();
        dkg = contracts.dkg;
        membership = contracts.dkgMembership;
    }

    function testRegisterNewDKG() public {
        vm.expectEmit(true, true, false, false);
        emit NewDKGCreated(address(dkg));

        vm.prank(owner);
        manager.registerNewDKG(dkg);
    }

    function testCannotRegisterNewDKGIfNotOwner() public {
        vm.prank(notOwner);
        vm.expectRevert(Ownable.Unauthorized.selector);
        manager.registerNewDKG(dkg);
    }
}
