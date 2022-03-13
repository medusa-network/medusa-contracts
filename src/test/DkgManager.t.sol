// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12;

import "../DkgManager.sol";
import "ds-test/test.sol";

interface CheatCodes {
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
        manager.startRegistration();
        manager.registerParticipant(1);
        testing.expectRevert(bytes("Invalid state transition to REGISTRATION"));
        manager.startRegistration();
        manager.startDKG();
        testing.expectRevert(bytes("Invalid state transition to DKG_DEALS"));
        manager.startDKG();


    }



    function testRegister() public {
        manager.startRegistration();
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
