// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "../DkgManager.sol";
import "ds-test/test.sol";

interface CheatCodes {
  function roll(uint256) external;
  function prank(address) external;
  function expectRevert(bytes calldata) external;
}

contract DKGTest is DSTest {
    DKGManager manager; 
    CheatCodes testing = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        manager = new DKGManager();
    }

    function testExample() public {
        assertTrue(true);
    }

    function testStatus() public {
        testing.expectRevert(bytes("You can not register yet!"));
        manager.registerParticipant(1);
        // we only accept registering after one block
        testing.roll(block.number + 1);
        manager.registerParticipant(1);
    }



    function testRegister() public {
        testing.roll(block.number + 1);
        assertEq(manager.numberParticipants(),0);
        manager.registerParticipant(1); // key != 0
        testing.expectRevert(
            bytes("Already registered participant"));
        manager.registerParticipant(10); // the address matters

        for (uint i = 1; i < manager.MAX_PARTICIPANTS();i++) {
            testing.prank(address(uint160(i)));
            manager.registerParticipant(i+1); // key != 0
            assertEq(manager.numberParticipants(),i+1);
        }
        testing.expectRevert(
            bytes("too many participants registered"));
        manager.registerParticipant(1);    
    }
}
