// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "../EncryptionOracle.sol";
import "../RoleACL.sol";
import "ds-test/test.sol";

interface CheatCodes {
  function roll(uint256) external;
  function prank(address) external;
  function expectRevert(bytes calldata) external;
}

contract ContractTest is DSTest {
    EncryptionOracle oracle; 
    CheatCodes testing = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        oracle = new EncryptionOracle();
    }

    function testSubmitCiphertext() public {
        RoleACL acl = new RoleACL(address(oracle));
        uint256 id = acl.submitCiphertext(acl.READER_ROLE(), 1,2);
        address bob = address(0x02);
        uint256 bobkey = 3;
        acl.grantRoleKey(acl.READER_ROLE(),bob,bobkey);
        testing.prank(bob);
        acl.askForDecryption(id);
     
    }
}
