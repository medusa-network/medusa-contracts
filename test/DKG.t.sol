// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {DKG} from "../src/DKG.sol";
import {DKGFactory} from "../src/DKGFactory.sol";
import "ds-test/test.sol";

interface CheatCodes {
    function roll(uint256) external;
    function prank(address) external;
    function expectRevert(bytes calldata) external;
}

contract DKGTest is DSTest {
    DKG dkg;
    CheatCodes testing = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        DKGFactory factory = new DKGFactory();
        dkg = new DKG(factory);
    }

    function testExample() public {
        assertTrue(true);
    }

    function testStatus() public {
        testing.roll(block.number + 1);
        dkg.registerParticipant(1);
    }

    function testRegister() public {
        testing.roll(block.number + 1);
        assertEq(dkg.numberParticipants(), 0);
        dkg.registerParticipant(1); // key != 0
        testing.expectRevert(bytes("Already registered participant"));
        dkg.registerParticipant(10); // the address matters

        for (uint256 i = 1; i < dkg.MAX_PARTICIPANTS(); i++) {
            testing.prank(address(uint160(i)));
            dkg.registerParticipant(i + 1); // key != 0
            assertEq(dkg.numberParticipants(), i + 1);
        }
        testing.expectRevert(bytes("too many participants registered"));
        dkg.registerParticipant(1);
    }
}
