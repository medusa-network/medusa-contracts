// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BN254EncryptionOracle} from "./BN254EncryptionOracle.sol";
import {Ciphertext} from "./EncryptionOracle.sol";
import {Bn128, G1Point} from "./Bn128.sol";

/*import "./altbn128.sol";*/

contract Playground is BN254EncryptionOracle {
    using Bn128 for G1Point;
    using Bn128 for bytes32;

    uint256 private nonce;

    G1Point private accumulator;

    /*altbn128.G1Point private acc2;*/

    constructor() BN254EncryptionOracle(Bn128.g1Zero()) {
        accumulator = Bn128.g1Zero();
        /*acc2 = altbn128.P1();*/
        /*acc2.X = 0;*/
        /*acc2.y = 0;*/
    }

    function compressPoint(G1Point memory _point) public pure returns (uint256) {
        return uint256(_point.g1Compress());
    }

    function parityPoint(G1Point memory _point) public pure returns (uint8) {
        return uint8(bytes32(_point.y)[31] & 0x01);
    }

    function decompressPoint(uint256 _point) public view returns (G1Point memory) {
        return bytes32(_point).g1Decompress();
    }

    // used to quickly setup a dist key without going through the whole DKG
    // onchain
    function setDistributedKey(G1Point memory _point) public onlyOwner {
        require(nonce == 0, "distributed key already setup!");
        require(_point.isG1PointOnCurve() == true, "point not on curve");
        distKey = _point;
        nonce = block.number;
    }

    function addAccumulatorCompressed(uint256 _x) public {
        G1Point memory point = bytes32(_x).g1Decompress();
        addAccumulator(point);
    }

    function addAccumulator(G1Point memory point) public {
        /*Bn128.G1Point memory point = G1Point(_x,_y);*/
        accumulator = accumulator.g1Add(point);
    }

    function getAccumulator() public view returns (G1Point memory) {
        return accumulator;
    }

    function getAccumulatorCompressed() public view returns (uint256) {
        return uint256(Bn128.g1Compress(getAccumulator()));
    }

    event NewLogCipher(uint256 indexed id, uint256 rx, uint256 ry, uint256 cipher);

    function logCipher(uint256 id, Ciphertext memory _cipher) public {
        emit NewLogCipher(id, _cipher.random.x, _cipher.random.y, _cipher.cipher);
    }
}
