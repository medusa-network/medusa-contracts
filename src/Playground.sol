// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import {EncryptionOracle, IEncryptionOracle as IO} from "./EncryptionOracle.sol";
import "./Bn128.sol";
/*import "./altbn128.sol";*/

contract TestContract is EncryptionOracle {
    uint256 private nonce;

    Bn128.G1Point private accumulator;
    /*altbn128.G1Point private acc2;*/

    constructor() EncryptionOracle() {
        accumulator = Bn128.g1Zero();
        /*acc2 = altbn128.P1();*/
        /*acc2.X = 0;*/
        /*acc2.y = 0;*/
    }

    function compressPoint(Bn128.G1Point memory _point) public pure returns (uint256) {
        return uint256(Bn128.g1Compress(_point));
    }

    function parityPoint(Bn128.G1Point memory _point) public pure returns (uint8) {
        return uint8(bytes32(_point.y)[31] & 0x01);
    }

    function decompressPoint(uint256 _point) public view returns (Bn128.G1Point memory) {
        return Bn128.g1Decompress(bytes32(_point));
    }

    // used to quickly setup a dist key without going through the whole DKG
    // onchain
    function setDistributedKey(Bn128.G1Point memory _point) public onlyOwner {
        require(nonce == 0, "distributed key already setup!");
        require(Bn128.isG1PointOnCurve(_point) == true, "point not on curve");
        dist_key = _point;
        nonce = block.number;
    }

    function addAccumulatorCompressed(uint256 _x) public {
        Bn128.G1Point memory point = Bn128.g1Decompress(bytes32(_x));
        addAccumulator(point);
    }

    function addAccumulator(Bn128.G1Point memory point) public {
        /*Bn128.G1Point memory point = G1Point(_x,_y);*/
        accumulator = Bn128.g1Add(accumulator, point);
    }

    function getAccumulator() public view returns (Bn128.G1Point memory) {
        return accumulator;
    }

    function getAccumulatorCompressed() public view returns (uint256) {
        return uint256(Bn128.g1Compress(getAccumulator()));
    }

    event NewLogCipher(uint256 indexed id, uint256 rx, uint256 ry, uint256 cipher);

    function logCipher(uint256 id, IO.Ciphertext memory _cipher) public {
        emit NewLogCipher(id, _cipher.random.x, _cipher.random.y, _cipher.cipher);
    }
}
