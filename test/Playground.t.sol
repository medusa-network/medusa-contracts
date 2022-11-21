// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "ds-test/test.sol";
import "forge-std/Test.sol";
import {Playground} from "../src/Playground.sol";
import {Bn128, G1Point, DleqProof} from "../src/Bn128.sol";

contract PlaygroundTest is Test {
    Playground private client;
    FakeDleq private fake;

    function setUp() public {
        client = new Playground();
        fake = fakeDleq();
    }

    struct FakeDleq {
        G1Point g1;
        G1Point g2;
        DleqProof proof;
    }

    function fakeDleq() public returns (FakeDleq memory) {
        uint256 f = 21888242871839275222246405745257275088548364400416034343698204186575808495133;
        uint256 e = 21888242871839275222246405745257275088548364400416034343698204186575808495134;
        G1Point memory g1 = Bn128.scalarMultiply(Bn128.g1(), f);
        G1Point memory g2 = Bn128.scalarMultiply(
            Bn128.scalarMultiply(Bn128.g1(), e),
            f
        );
        return FakeDleq(g1, g2, DleqProof(f, e));
    }

    function verifyDleq(
        G1Point calldata g1,
        G1Point calldata g2,
        DleqProof calldata proof,
        uint256 label
    ) public returns (bool) {
        return Bn128.dleqverify(g1, g2, proof, label);
    }

    function testDleqVerification() public {
        // have to separate via own function to use "this" to convert
        // from memory to calldata
        assertEq(this.verifyDleq(fake.g1, fake.g2, fake.proof, 0), false);
    }

    function testPairingVerification() public {}

    function testShaThis() public {
        client.shathis(Bn128.g1(), address(this), Bn128.g1());
    }
}
