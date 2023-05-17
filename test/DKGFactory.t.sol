// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {MedusaTest} from "./MedusaTest.sol";
import {DKGFactory} from "../src/DKGFactory.sol";
import {Bn128} from "../src/utils/Bn128.sol";
import {DeployFactories} from "../script/DeployFactories.s.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract DKGFactoryTest is MedusaTest {
    DKGFactory factory;
    address authorizedNode = makeAddr("authorizedNode");
    address notAuthorizedNode = makeAddr("notAuthorizedNode");

    function setUp() public {
        factory = new DeployFactories().run().dkgFactory;
    }

    function testDeployNewDKG() public {
        vm.prank(owner);
        address dkgAddress = address(factory.deployNewDKG());
        assertEq(factory.dkgAddresses(dkgAddress), true);

        vm.prank(owner);
        address secondDKGAddress = address(factory.deployNewDKG());
        assertEq(factory.dkgAddresses(secondDKGAddress), true);

        assertFalse(dkgAddress == secondDKGAddress);
    }

    function testCannotDeployNewDKGIfNotOwner() public {
        vm.prank(notOwner);
        vm.expectRevert(Ownable.Unauthorized.selector);
        factory.deployNewDKG();
    }

    function testAddAuthorizedNode() public {
        assertFalse(factory.isAuthorizedNode(authorizedNode));

        vm.prank(owner);
        factory.addAuthorizedNode(authorizedNode);
        assert(factory.isAuthorizedNode(authorizedNode));
    }

    function testCannotAddAuthorizedNodeIfNotOwner() public {
        assertFalse(factory.isAuthorizedNode(notAuthorizedNode));

        vm.prank(notOwner);
        vm.expectRevert(Ownable.Unauthorized.selector);
        factory.addAuthorizedNode(notAuthorizedNode);

        assertFalse(factory.isAuthorizedNode(notAuthorizedNode));
    }

    function testRemoveAuthorizedNode() public {
        vm.prank(owner);
        factory.addAuthorizedNode(authorizedNode);
        assert(factory.isAuthorizedNode(authorizedNode));

        vm.prank(owner);
        factory.removeAuthorizedNode(authorizedNode);
        assertFalse(factory.isAuthorizedNode(authorizedNode));
    }

    function testCannotRemoveAuthorizedNodeIfNotOwner() public {
        vm.prank(owner);
        factory.addAuthorizedNode(authorizedNode);
        assert(factory.isAuthorizedNode(authorizedNode));

        vm.prank(notOwner);
        vm.expectRevert(Ownable.Unauthorized.selector);
        factory.removeAuthorizedNode(authorizedNode);

        assert(factory.isAuthorizedNode(authorizedNode));
    }
}
