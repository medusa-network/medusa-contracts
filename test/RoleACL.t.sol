// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IEncryptionOracle as IO, EncryptionOracle} from "../src/EncryptionOracle.sol";
import {BN254EncryptionOracle} from "../src/BN254EncryptionOracle.sol";
import {RoleACL} from "../src/RoleACL.sol";
import {Bn128} from "../src/Bn128.sol";
import "forge-std/Test.sol";

contract RoleACLTest is Test {
    IO oracle;

    function setUp() public {
        oracle = new BN254EncryptionOracle(Bn128.g1Zero());
    }

    function testSubmitCiphertext() public {
        RoleACL acl = new RoleACL(address(oracle));
        Bn128.G1Point memory key = Bn128.G1Point(1, 2);
        IO.Ciphertext memory c = IO.Ciphertext(key, 3);
        uint256 id = acl.submitCiphertext(c);
        address bob = address(0x02);
        acl.grantRoleKey(acl.READER_ROLE(), bob, key);
        vm.prank(bob);
        acl.askForDecryption(id);
    }
}
