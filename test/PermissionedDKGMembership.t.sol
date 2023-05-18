// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {MedusaTest} from "./MedusaTest.sol";
import {PermissionedDKGMembership} from "../src/PermissionedDKGMembership.sol";
import {Bn128} from "../src/utils/Bn128.sol";
import {Ownable} from "solady/auth/Ownable.sol";

contract PermissionedDKGMembershipTest is MedusaTest {
    PermissionedDKGMembership private membership;

    address private authorizedNode = makeAddr("authorizedNode");
    address private notAuthorizedNode = makeAddr("notAuthorizedNode");

    function setUp() public {
        membership = new PermissionedDKGMembership(owner);
    }

    function testAddAuthorizedNode() public {
        assertFalse(membership.isAuthorizedNode(authorizedNode));

        vm.prank(owner);
        membership.addAuthorizedNode(authorizedNode);
        assert(membership.isAuthorizedNode(authorizedNode));
    }

    function testCannotAddAuthorizedNodeIfNotOwner() public {
        assertFalse(membership.isAuthorizedNode(notAuthorizedNode));

        vm.prank(notOwner);
        vm.expectRevert(Ownable.Unauthorized.selector);
        membership.addAuthorizedNode(notAuthorizedNode);

        assertFalse(membership.isAuthorizedNode(notAuthorizedNode));
    }

    function testRemoveAuthorizedNode() public {
        vm.prank(owner);
        membership.addAuthorizedNode(authorizedNode);
        assert(membership.isAuthorizedNode(authorizedNode));

        vm.prank(owner);
        membership.removeAuthorizedNode(authorizedNode);
        assertFalse(membership.isAuthorizedNode(authorizedNode));
    }

    function testCannotRemoveAuthorizedNodeIfNotOwner() public {
        vm.prank(owner);
        membership.addAuthorizedNode(authorizedNode);
        assert(membership.isAuthorizedNode(authorizedNode));

        vm.prank(notOwner);
        vm.expectRevert(Ownable.Unauthorized.selector);
        membership.removeAuthorizedNode(authorizedNode);

        assert(membership.isAuthorizedNode(authorizedNode));
    }
}
