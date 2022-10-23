// SPDX-License-Identifier: MIT

// parts extracted/inspired from https://github.com/keep-network/keep-core/edit/main/solidity/random-beacon/contracts/libraries/AltBn128.sol
pragma solidity ^0.8.17;

// G1Point implements a point in G1 group.

struct G1Point {
    uint256 x;
    uint256 y;
}

struct DleqProof {
    uint256 f;
    uint256 e;
}

/// @title Operations on bn128
/// @dev Implementations of common elliptic curve operations on Ethereum's
///      alt_bn128 curve. Whenever possible, use post-Byzantium
///      pre-compiled contracts to offset gas costs.
library Bn128 {
    using ModUtils for uint256;

    // p is a prime over which we form a basic field
    // Taken from go-ethereum/crypto/bn256/cloudflare/constants.go
    uint256 internal constant p = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    /// @dev Gets generator of G1 group.
    ///      Taken from go-ethereum/crypto/bn256/cloudflare/curve.go
    uint256 internal constant g1x = 1;
    uint256 internal constant g1y = 2;

    //// --------------------
    ////       DLEQ PART
    //// --------------------
    uint256 internal constant base2x = 5671920232091439599101938152932944148754342563866262832106763099907508111378;
    uint256 internal constant base2y = 2648212145371980650762357218546059709774557459353804686023280323276775278879;
    uint256 internal constant r = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /// TODO XXX Can't extract that in its own library because then can't instantiate in Typescript correctly
    /// Seems like a linked library problem with typechain.
    function dleqverify(G1Point calldata _rg1, G1Point calldata _rg2, DleqProof calldata _proof, uint256 _label)
        internal
        view
        returns (
            //) internal view returns (G1Point memory) {
            bool
        )
    {
        // w1 = f*G1 + rG1 * e
        G1Point memory w1 = g1Add(scalarMultiply(g1(), _proof.f), scalarMultiply(_rg1, _proof.e));
        // w2 = f*G2 + rG2 * e
        G1Point memory w2 = g1Add(scalarMultiply(G1Point(base2x, base2y), _proof.f), scalarMultiply(_rg2, _proof.e));
        uint256 challenge =
            uint256(sha256(abi.encodePacked(_label, _rg1.x, _rg1.y, _rg2.x, _rg2.y, w1.x, w1.y, w2.x, w2.y))) % r;
        if (challenge == _proof.e) {
            return true;
        }
        return false;
    }

    function g1Zero() internal pure returns (G1Point memory) {
        return G1Point(0, 0);
    }

    /// @dev Decompress a point on G1 from a single uint256.
    function g1Decompress(bytes32 m) internal view returns (G1Point memory) {
        unchecked {
            bytes32 mX = bytes32(0);
            bytes1 leadX = m[0] & 0x7f;
            // slither-disable-next-line incorrect-shift
            uint256 mask = 0xff << (31 * 8);
            mX = (m & ~bytes32(mask)) | (leadX >> 0);

            uint256 x = uint256(mX);
            uint256 y = g1YFromX(x);

            if (parity(y) != (m[0] & 0x80) >> 7) {
                y = p - y;
            }

            require(isG1PointOnCurve(G1Point(x, y)), "Malformed bn256.G1 point.");

            return G1Point(x, y);
        }
    }

    /// @dev Wraps the scalar point multiplication pre-compile introduced in
    ///      Byzantium. The result of a point from G1 multiplied by a scalar
    ///      should match the point added to itself the same number of times.
    ///      Revert if the provided point isn't on the curve.
    function scalarMultiply(G1Point memory p_1, uint256 scalar) internal view returns (G1Point memory p_2) {
        // 0x07     id of the bn256ScalarMul precompile
        // 0        number of ether to transfer
        // 96       size of call parameters, i.e. 96 bytes total (256 bit for x, 256 bit for y, 256 bit for scalar)
        // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
        assembly {
            let arg := mload(0x40)
            mstore(arg, mload(p_1))
            mstore(add(arg, 0x20), mload(add(p_1, 0x20)))
            mstore(add(arg, 0x40), scalar)
            // 0x07 is the ECMUL precompile address
            if iszero(staticcall(not(0), 0x07, arg, 0x60, p_2, 0x40)) { revert(0, 0) }
        }
    }

    /// @dev Wraps the point addition pre-compile introduced in Byzantium.
    ///      Returns the sum of two points on G1. Revert if the provided points
    ///      are not on the curve.
    function g1Add(G1Point memory a, G1Point memory b) internal view returns (G1Point memory c) {
        assembly {
            let arg := mload(0x40)
            mstore(arg, mload(a))
            mstore(add(arg, 0x20), mload(add(a, 0x20)))
            mstore(add(arg, 0x40), mload(b))
            mstore(add(arg, 0x60), mload(add(b, 0x20)))
            // 0x60 is the ECADD precompile address
            if iszero(staticcall(not(0), 0x06, arg, 0x80, c, 0x40)) { revert(0, 0) }
        }
    }

    /// @dev Returns true if G1 point is on the curve.
    function isG1PointOnCurve(G1Point memory point) internal view returns (bool) {
        return point.y.modExp(2, p) == (point.x.modExp(3, p) + 3) % p;
    }

    /// @dev Compress a point on G1 to a single uint256 for serialization.
    function g1Compress(G1Point memory point) internal pure returns (bytes32) {
        bytes32 m = bytes32(point.x);

        // first byte with the first bit set as parity -> 1 = even, 0 = odd
        // even <-- 1xxxxxxx
        bytes1 leadM = m[0] | (parity(point.y) << 7);
        // slither-disable-next-line incorrect-shift
        // 0xff000....00
        uint256 mask = 0xff << (31 * 8);
        // m & 00ffffffff -> that keeps the lowest parts of m  and then add the
        // lead bit
        // even <-- 1xxxxxxx  m[1..j]
        m = (m & ~bytes32(mask)) | (leadM >> 0);

        return m;
    }

    /// @dev g1YFromX computes a Y value for a G1 point based on an X value.
    ///      This computation is simply evaluating the curve equation for Y on a
    ///      given X, and allows a point on the curve to be represented by just
    ///      an X value + a sign bit.
    // TODO: Sqrt can be cheaper by giving the y value directly and computing
    // the check y_witness^2 = y^2
    function g1YFromX(uint256 x) internal view returns (uint256) {
        return ((x.modExp(3, p) + 3) % p).modSqrt(p);
    }

    /// @dev Calculates whether the provided number is even or odd.
    /// @return 0x01 if y is an even number and 0x00 if it's odd.
    function parity(uint256 value) public pure returns (bytes1) {
        return bytes32(value)[31] & 0x01;
    }

    function g1() public pure returns (G1Point memory) {
        return G1Point(g1x, g1y);
    }
}

library ModUtils {
    /// @dev Wraps the modular exponent pre-compile introduced in Byzantium.
    ///      Returns base^exponent mod p.
    function modExp(uint256 base, uint256 exponent, uint256 p) internal view returns (uint256 o) {
        assembly {
            // Args for the precompile: [<length_of_BASE> <length_of_EXPONENT>
            // <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>]
            let output := mload(0x40)
            let args := add(output, 0x20)
            mstore(args, 0x20)
            mstore(add(args, 0x20), 0x20)
            mstore(add(args, 0x40), 0x20)
            mstore(add(args, 0x60), base)
            mstore(add(args, 0x80), exponent)
            mstore(add(args, 0xa0), p)

            // 0x05 is the modular exponent contract address
            if iszero(staticcall(not(0), 0x05, args, 0xc0, output, 0x20)) { revert(0, 0) }
            o := mload(output)
        }
    }

    /// @dev Calculates and returns the square root of a mod p if such a square
    ///      root exists. The modulus p must be an odd prime. If a square root
    ///      does not exist, function returns 0.
    // TODO avoid thiisssssss by giving witness
    function modSqrt(uint256 a, uint256 p) internal view returns (uint256) {
        unchecked {
            if (legendre(a, p) != 1) {
                return 0;
            }

            if (a == 0) {
                return 0;
            }

            if (p % 4 == 3) {
                return modExp(a, (p + 1) / 4, p);
            }

            uint256 s = p - 1;
            uint256 e = 0;

            while (s % 2 == 0) {
                s = s / 2;
                e = e + 1;
            }

            // Note the smaller int- finding n with Legendre symbol or -1
            // should be quick
            uint256 n = 2;
            while (legendre(n, p) != -1) {
                n = n + 1;
            }

            uint256 x = modExp(a, (s + 1) / 2, p);
            uint256 b = modExp(a, s, p);
            uint256 g = modExp(n, s, p);
            uint256 r = e;
            uint256 gs = 0;
            uint256 m = 0;
            uint256 t = b;

            while (true) {
                t = b;
                m = 0;

                for (m = 0; m < r; m++) {
                    if (t == 1) {
                        break;
                    }
                    t = modExp(t, 2, p);
                }

                if (m == 0) {
                    return x;
                }

                gs = modExp(g, uint256(2) ** (r - m - 1), p);
                g = (gs * gs) % p;
                x = (x * gs) % p;
                b = (b * g) % p;
                r = m;
            }
        }
        return 0;
    }

    /// @dev Calculates the Legendre symbol of the given a mod p.
    /// @return Returns 1 if a is a quadratic residue mod p, -1 if it is
    ///         a non-quadratic residue, and 0 if a is 0.
    function legendre(uint256 a, uint256 p) internal view returns (int256) {
        unchecked {
            uint256 raised = modExp(a, (p - 1) / uint256(2), p);

            if (raised == 0 || raised == 1) {
                return int256(raised);
            } else if (raised == p - 1) {
                return -1;
            }

            require(false, "Failed to calculate legendre.");
            return 0;
        }
    }
}
