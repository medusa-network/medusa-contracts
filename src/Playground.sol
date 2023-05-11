// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BN254EncryptionOracle} from "./BN254EncryptionOracle.sol";
import {COMPLAINT_LABEL, IDKGMembership} from "./DKG.sol";
import {Ciphertext} from "./interfaces/IEncryptionOracle.sol";
import {Bn128, G1Point, DleqProof} from "./Bn128.sol";

//import {Dleq} from "./DleqBN128.sol";

/*import "./altbn128.sol";*/

contract Playground is BN254EncryptionOracle, IDKGMembership {
    using Bn128 for G1Point;
    using Bn128 for bytes32;

    uint256 private nonce;

    G1Point private accumulator;
    address private oracle;

    /*altbn128.G1Point private acc2;*/

    constructor() BN254EncryptionOracle(Bn128.g1Zero(), address(0), 0, 0) {
        accumulator = Bn128.g1Zero();
        /*acc2 = altbn128.P1();*/
        /*acc2.X = 0;*/
        /*acc2.y = 0;*/
    }

    function isAuthorizedNode(address) external view virtual returns (bool) {
        // everybody is authorized ! It's for testing purpose, without
        // having to launch a full DKG factory, and being able to control the launch
        // of the DKG directly.
        return true;
    }

    function compressPoint(G1Point calldata _point)
        external
        pure
        returns (uint256)
    {
        return uint256(_point.g1Compress());
    }

    function parityPoint(G1Point calldata _point)
        external
        pure
        returns (uint8)
    {
        return uint8(bytes32(_point.y)[31] & 0x01);
    }

    function decompressPoint(uint256 _point)
        external
        view
        returns (G1Point memory)
    {
        return bytes32(_point).g1Decompress();
    }

    // used to quickly setup a dist key without going through the whole DKG
    // onchain
    function setDistributedKey(G1Point calldata _point) external onlyOwner {
        require(nonce == 0, "distributed key already setup!");
        require(_point.isG1PointOnCurve() == true, "point not on curve");
        distKey = _point;
        nonce = block.number;
    }

    function addAccumulatorCompressed(uint256 _x) external {
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
        return uint256(getAccumulator().g1Compress());
    }

    event NewLogCipher(
        uint256 indexed id, uint256 rx, uint256 ry, uint256 cipher
    );

    function logCipher(uint256 id, Ciphertext calldata _cipher) external {
        emit NewLogCipher(
            id, _cipher.random.x, _cipher.random.y, _cipher.cipher
        );
    }

    function scalarMul(G1Point calldata p, uint256 r)
        public
        view
        returns (G1Point memory)
    {
        return Bn128.scalarMultiply(p, r);
    }

    function pointAdd(G1Point calldata p1, G1Point calldata p2)
        public
        view
        returns (G1Point memory)
    {
        return Bn128.g1Add(p1, p2);
    }

    function identity(G1Point calldata p1)
        public
        pure
        returns (G1Point memory)
    {
        return p1;
    }

    function idScalar(uint256 s) public pure returns (uint256) {
        return s;
    }

    function deployOracle(
        G1Point memory distkey,
        address relayer,
        uint96 submissionFee,
        uint96 reencryptionFee
    ) public returns (address) {
        BN254EncryptionOracle _oracle = new BN254EncryptionOracle(
            distkey,
            relayer,
            submissionFee,
            reencryptionFee
        );
        oracle = address(_oracle);
        distKey = distkey;
        return oracle;
    }

    function submitCiphertextToOracle(
        Ciphertext calldata _cipher,
        address _encryptor
    ) public payable returns (uint256) {
        require(oracle != address(0), "oracle not deployed");
        return BN254EncryptionOracle(oracle).submitCiphertext{value: msg.value}(
            _cipher, _encryptor
        );
    }

    function verifyDLEQProof(
        G1Point calldata _rg1,
        G1Point calldata _rg2,
        DleqProof calldata _proof,
        uint256 _label
    )
        public
        view
        returns (
            // ) public view returns (G1Point memory) {
            bool
        )
    {
        return Bn128.dleqverify(_rg1, _rg2, _proof, _label);
    }

    function debugDleq(
        G1Point calldata _base1,
        G1Point calldata _base2,
        G1Point calldata _rg1,
        G1Point calldata _rg2,
        DleqProof calldata _proof,
        uint256 _label
    ) public view returns (uint256) {
        G1Point memory w1 = Bn128.g1Add(
            Bn128.scalarMultiply(_base1, _proof.f),
            Bn128.scalarMultiply(_rg1, _proof.e)
        );
        G1Point memory w2 = Bn128.g1Add(
            Bn128.scalarMultiply(_base2, _proof.f),
            Bn128.scalarMultiply(_rg2, _proof.e)
        );
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
        ) % Bn128.r;

        return challenge;
    }

    function verifyDleqProofWithBases(
        G1Point calldata _base1,
        G1Point calldata _base2,
        G1Point calldata _rg1,
        G1Point calldata _rg2,
        DleqProof calldata _proof,
        uint256 _label
    ) public view returns (bool) {
        return Bn128.dleqVerifyWithBases(
            _base1, _base2, _rg1, _rg2, _proof, _label
        );
    }

    function shathis(
        G1Point calldata label_point,
        address label_addr,
        G1Point calldata hashPoint
    ) public pure returns (uint256) {
        uint256 label = uint256(
            sha256(abi.encodePacked(label_addr, label_point.x, label_point.y))
        );
        return
            uint256(sha256(abi.encodePacked(label, hashPoint.x, hashPoint.y)));
    }

    function transcript_verify(
        G1Point calldata p1,
        address addr,
        uint256 expect
    ) public pure returns (bool) {
        uint256 fs =
            uint256(sha256(abi.encodePacked(p1.x, p1.y, addr))) % Bn128.r;
        if (fs == expect) {
            return true;
        }
        revert("invalid transcript result");
    }

    // ---------- simple units tests
    function shaUint256Input(uint256 input) public pure returns (uint256) {
        return uint256(sha256(abi.encodePacked(input)));
    }

    function getConstSha() public pure returns (uint256) {
        return uint256(1337);
    }

    function shaUint256Const() public pure returns (uint256) {
        return shaUint256Input(getConstSha());
    }

    function doubleShaUint256(uint256 input) public pure returns (uint256) {
        uint256 lvl1 = shaUint256Input(input);
        return shaUint256Input(lvl1);
    }

    function shaPoint(G1Point memory input) public pure returns (uint256) {
        return uint256(sha256(abi.encodePacked(input.x, input.y)));
    }

    function shaChallenge(uint256 input) public pure returns (uint256) {
        uint256 challenge = shaUint256Input(input) % Bn128.r;
        return challenge;
    }

    function polynomial_eval(G1Point[] memory poly, uint256 eval)
        public
        view
        returns (G1Point memory)
    {
        return Bn128.publicPolyEval(poly, eval);
    }
}
