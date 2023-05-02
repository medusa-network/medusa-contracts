// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "ds-test/test.sol";
import "forge-std/Test.sol";
import {Playground} from "../src/Playground.sol";
import {Bn128, ModUtils, G1Point, DleqProof} from "../src/Bn128.sol";

contract PlaygroundTest is Test {
    using ModUtils for uint256;

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

    function fakeDleq() public view returns (FakeDleq memory) {
        uint256 f =
            21888242871839275222246405745257275088548364400416034343698204186575808495133;
        uint256 e =
            21888242871839275222246405745257275088548364400416034343698204186575808495134;
        G1Point memory g1 = Bn128.scalarMultiply(Bn128.g1(), f);
        G1Point memory g2 =
            Bn128.scalarMultiply(Bn128.scalarMultiply(Bn128.g1(), e), f);
        return FakeDleq(g1, g2, DleqProof(f, e));
    }

    function verifyDleq(
        G1Point calldata g1,
        G1Point calldata g2,
        DleqProof calldata proof,
        uint256 label
    ) public view returns (bool) {
        return Bn128.dleqverify(g1, g2, proof, label);
    }

    function testDleqVerification() public {
        // have to separate via own function to use "this" to convert
        // from memory to calldata
        assertEq(this.verifyDleq(fake.g1, fake.g2, fake.proof, 0), false);
    }

    // TODO put this in bn128 tests

    function randomPoint(uint256 offset) public view returns (G1Point memory) {
        uint256 scalar = offset + 111111111111111111111111111111111111;
        return Bn128.scalarMultiply(Bn128.base1(), scalar);
    }

    function testPolyEval() public {
        G1Point memory A = randomPoint(1);
        G1Point memory B = randomPoint(2);
        G1Point memory C = randomPoint(3);

        G1Point[] memory poly = new G1Point[](3);
        poly[0] = A;
        poly[1] = B;
        poly[2] = C;
        // poly is = a + x*b + x²*c
        uint256 eval_point = 2;
        G1Point memory exp_result = A;
        {
            G1Point memory bx = Bn128.scalarMultiply(B, eval_point);
            G1Point memory cx2 = Bn128.scalarMultiply(
                Bn128.scalarMultiply(C, eval_point), eval_point
            );
            exp_result = Bn128.g1Add(Bn128.g1Add(A, bx), cx2);
        }
        // eval result
        // C -> C*index + B -> C*index*index + B*index + A
        G1Point memory comp_result = client.polynomial_eval(poly, eval_point);
        assertEq(Bn128.g1Equal(comp_result, exp_result), true);
    }
}
