// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {DKGFactory} from "../src/DKGFactory.sol";
import {Bn128} from "../src/Bn128.sol";

contract DKGFactoryTest is Test {
    DKGFactory factory;

    function setUp() public {
        factory = new DKGFactory();
    }

    function testDeployNewDKG() public {
        address dkgAddress = factory.deployNewDKG();
        assertEq(factory.dkgAddresses(dkgAddress), true);

        address secondDKGAddress = factory.deployNewDKG();
        assertEq(factory.dkgAddresses(secondDKGAddress), true);

        assertFalse(dkgAddress == secondDKGAddress);
    }

    function testCannotDeployNewDKGIfNotOwner() public {
        vm.prank(address(uint160(12345)));
        vm.expectRevert("Ownable: caller is not the owner");
        factory.deployNewDKG();
    }

    function testAddAuthorizedNode() public {
        address authorizedNode = address(uint160(12345));
        assertFalse(factory.isAuthorizedNode(authorizedNode));

        factory.addAuthorizedNode(authorizedNode);
        assert(factory.isAuthorizedNode(authorizedNode));
    }

    function testCannotAddAuthorizedNodeIfNotOwner() public {
        address notOwner = address(uint160(12345));
        address notAuthorizedNode = address(uint160(98765));
        assertFalse(factory.isAuthorizedNode(notAuthorizedNode));

        vm.prank(notOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        factory.addAuthorizedNode(notAuthorizedNode);

        assertFalse(factory.isAuthorizedNode(notAuthorizedNode));
    }

    function testRemoveAuthorizedNode() public {
        address authorizedNode = address(uint160(12345));
        factory.addAuthorizedNode(authorizedNode);
        assert(factory.isAuthorizedNode(authorizedNode));

        factory.removeAuthorizedNode(authorizedNode);
        assertFalse(factory.isAuthorizedNode(authorizedNode));
    }

    function testCannotRemoveAuthorizedNodeIfNotOwner() public {
        address notOwner = address(uint160(12345));
        address authorizedNode = address(uint160(98765));
        factory.addAuthorizedNode(authorizedNode);
        assert(factory.isAuthorizedNode(authorizedNode));

        vm.prank(notOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        factory.removeAuthorizedNode(authorizedNode);

        assert(factory.isAuthorizedNode(authorizedNode));
    }
}
