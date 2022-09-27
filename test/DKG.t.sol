// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {DKG, NotAuthorized, AlreadyRegistered, ParticipantLimit} from "../src/DKG.sol";
import {DKGFactory} from "../src/DKGFactory.sol";
import "forge-std/Test.sol";

contract DKGTest is Test {
    DKG private dkg;
    DKGFactory private factory;

    function setUp() public {
        factory = new DKGFactory();
        dkg = new DKG(factory);
        factory.addAuthorizedNode(address(this));
    }

    function testStatus() public {
        vm.roll(block.number + 1);
        dkg.registerParticipant(1);
    }

    function testRegister() public {
        vm.roll(block.number + 1);
        assertEq(dkg.numberParticipants(), 0);
        dkg.registerParticipant(1); // key != 0
        vm.expectRevert(AlreadyRegistered.selector);
        dkg.registerParticipant(10); // the address matters

        for (uint256 i = 1; i < dkg.MAX_PARTICIPANTS(); i++) {
            address nextParticipant = address(uint160(i));
            factory.addAuthorizedNode(nextParticipant);
            vm.prank(nextParticipant);
            dkg.registerParticipant(i + 1); // key != 0
            assertEq(dkg.numberParticipants(), i + 1);
        }
        address nextParticipant = address(uint160(dkg.MAX_PARTICIPANTS()));
        factory.addAuthorizedNode(nextParticipant);
        vm.prank(nextParticipant);
        vm.expectRevert(ParticipantLimit.selector);
        dkg.registerParticipant(1);
    }
}
