// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "./EncryptionOracle.sol";
import "./Bn128.sol";
/*import "./altbn128.sol";*/

contract TestContract is EncryptionOracle {
    uint private nonce;

    Bn128.G1Point private accumulator;
    /*altbn128.G1Point private acc2;*/

    constructor() EncryptionOracle() {
        accumulator = Bn128.g1Zero();
        /*acc2 = altbn128.P1();*/
        /*acc2.X = 0;*/
        /*acc2.y = 0;*/
    }

    // used to quickly setup a dist key without going through the whole DKG
    // onchain
    function setDistributedKey(Bn128.G1Point memory _point) public onlyOwner {
        require(nonce == 0,"distributed key already setup!");
        dist_key = _point;
        nonce = block.number;
    }

    function addAccumulatorCompressed(uint256 _x) public {
        Bn128.G1Point memory point = Bn128.g1Decompress(bytes32(_x));
        addAccumulator(point);
    }

    function addAccumulator(Bn128.G1Point memory point) public {
        /*Bn128.G1Point memory point = G1Point(_x,_y);*/
        accumulator = Bn128.g1Add(accumulator,point);
    }

    function getAccumulator() public view returns (Bn128.G1Point memory) {
        return accumulator;
    }

    function getAccumulatorCompressed() public view returns (uint256) {
        return uint256(Bn128.g1Compress(getAccumulator()));
    }
}
