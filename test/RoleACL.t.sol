// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {Ciphertext} from "../src/interfaces/IEncryptionOracle.sol";
import {BN254EncryptionOracle} from "../src/BN254EncryptionOracle.sol";
import {RoleACL} from "../src/client/RoleACL.sol";
import {Bn128, G1Point} from "../src/utils/Bn128.sol";
import {MedusaTest} from "./MedusaTest.sol";

contract RoleACLTest is MedusaTest {
    BN254EncryptionOracle oracle;

    function setUp() public {
        oracle = new BN254EncryptionOracle();
        oracle.initialize(Bn128.g1Zero(), address(this), relayer, 0, 0);
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
