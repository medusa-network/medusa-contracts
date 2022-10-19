// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {G1Point, Bn128} from "./Bn128.sol";
import {Suite} from "../src/OracleFactory.sol";

/// DLEQ proof of equality between two bases
library BN254DefaultDleq {
    using Bn128 for G1Point;

    struct Proof {
        uint256 f;
        uint256 e;
    }

    uint256 internal constant base2x =
        5671920232091439599101938152932944148754342563866262832106763099907508111378;
    uint256 internal constant base2y =
        2648212145371980650762357218546059709774557459353804686023280323276775278879;

    /// match closely the JS implementation in src/encrypt.ts
    function verify(
        G1Point calldata _rg1,
        G1Point calldata _rg2,
        Proof calldata _proof,
        string calldata _label
    ) public view returns (bool) {
        G1Point memory w1 = Bn128.g1().scalarMultiply(_proof.f).g1Add(
            _rg1.scalarMultiply(_proof.e)
        );
        G1Point memory w2 = G1Point(base2x, base2y)
            .scalarMultiply(_proof.f)
            .g1Add(_rg1.scalarMultiply(_proof.e));
        uint256 challenge = uint256(
            sha256(
                abi.encodePacked(
                    _label,
                    _rg1.x,
                    _rg1.y,
                    _rg2.x,
                    _rg2.y,
                    w1.x,
                    w1.y,
                    w2.x,
                    w2.y
                )
            )
        );
        if (challenge == _proof.e) {
            return true;
        }
        return false;
    }

    function suite() external pure returns (Suite) {
        return Suite.BN254_KEYG1_HGAMAL;
    }
}
