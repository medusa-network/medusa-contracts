// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ciphertext, IEncryptionOracle as IO} from "../src/EncryptionOracle.sol";
import {BN254EncryptionOracle} from "../src/BN254EncryptionOracle.sol";
import {RoleACL} from "../src/RoleACL.sol";
import {Bn128, G1Point} from "../src/Bn128.sol";
import "forge-std/Test.sol";

contract RoleACLTest is Test {
    IO oracle;

    function setUp() public {
        oracle = new BN254EncryptionOracle(Bn128.g1Zero());
    }

    function testSubmitCiphertext() public {
        // TODO need to implement DLEQ valid proof for it
        //RoleACL acl = new RoleACL(address(oracle));
        //G1Point memory key = G1Point(1, 2);
        //Ciphertext memory c = Ciphertext(key, 3, key, Bn128.DleqProof(1, 2));
        //uint256 id = acl.submitCiphertext(c, "dummylink");
        //address bob = address(0x02);
        //acl.grantRoleKey(acl.READER_ROLE(), bob, key);
        //vm.prank(bob);
        //acl.askForDecryption(id);
    }
}
