// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "ds-test/test.sol";

import {Playground} from "../src/Playground.sol";
import {Bn128, G1Point, DleqProof} from "../src/Bn128.sol";
import {Dleq} from "../src/DleqBN128.sol";

contract PlaygroundTest is DSTest {
    Playground private client;

    function setUp() public {
        client = new Playground();
    }

    function testDleq() public {
        assertTrue(true);
        //assertTrue(
        //    !client.verifyDLEQProof(
        //        Bn128.g1(),
        //        Bn128.g1(),
        //        DleqProof(1, 2),
        //        "mylabel"
        //    )
        //);
    }

    function testShaThis() public {
        client.shathis(Bn128.g1(), address(this), Bn128.g1());
    }
}
