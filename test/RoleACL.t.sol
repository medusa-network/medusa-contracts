// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IEncryptionOracle as IO, EncryptionOracle} from "../src/EncryptionOracle.sol";
import "../src/RoleACL.sol";
import "../src/Bn128.sol";
import "ds-test/test.sol";

interface CheatCodes {
    function roll(uint256) external;
    function prank(address) external;
    function expectRevert(bytes calldata) external;
}

contract RoleACLTest is DSTest {
    IO oracle;
    CheatCodes testing = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        oracle = new EncryptionOracle();
    }

    function testSubmitCiphertext() public {
        RoleACL acl = new RoleACL(address(oracle));
        Bn128.G1Point memory key = Bn128.G1Point(1, 2);
        IO.Ciphertext memory c = IO.Ciphertext(key, 3);
        uint256 id = acl.submitCiphertext(c);
        address bob = address(0x02);
        acl.grantRoleKey(acl.READER_ROLE(), bob, key);
        testing.prank(bob);
        acl.askForDecryption(id);
    }
}
