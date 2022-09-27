// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IThresholdNetwork} from "./DKG.sol";
import {Bn128} from "./Bn128.sol";

interface IEncryptionClient {
    function oracleResult(uint256 request_id, IEncryptionOracle.Ciphertext memory _cipher) external;
}

interface IEncryptionOracle is IThresholdNetwork {
    struct Ciphertext {
        Bn128.G1Point random;
        uint256 cipher;
    }

    // returns the request id
    function requestReencryption(uint256 _cipher_id, Bn128.G1Point memory _publickey) external returns (uint256);
    // returns the ciphertext id
    function submitCiphertext(Ciphertext memory _cipher) external returns (uint256);
    // TODO Fix with a proper struct once
    // https://github.com/gakonst/ethers-rs/issues/1219 is fixed

    event NewCiphertext(uint256 indexed id, uint256 rx, uint256 ry, uint256 cipher, address client);
    event ReencryptionRequest(
        uint256 indexed cipher_id, uint256 request_id, uint256 pubx, uint256 puby, address client
    );
}

contract EncryptionOracle is IEncryptionOracle {
    // TODO authorization
    // who are the oracles sender that are allowed to push results
    //mapping(address => bool) authorized_oracle;
    address public authorized_client;

    // public key set by OracleFactory on deployment
    Bn128.G1Point internal distKey;

    struct PendingRequest {
        address client;
    }

    // pending request is used to track the reencryption requests, to make sure
    // the medusa node callsback the same contract that submitted the request in
    // the first place.
    mapping(uint256 => PendingRequest) private pending_requests;
    // counter to derive unique nonces for each ciphertext ever submitted to the oracle
    uint256 private cipher_nonce = 0;
    // counter to derive unique nonces for each reencryption request ever submitted to the oracle
    uint256 private request_nonce = 0;

    constructor(Bn128.G1Point memory _distKey) {
        distKey = _distKey;
    }

    function newCipherId() private returns (uint256) {
        cipher_nonce += 1;
        return cipher_nonce;
    }

    function newRequestId() private returns (uint256) {
        request_nonce += 1;
        return request_nonce;
    }

    function submitCiphertext(IEncryptionOracle.Ciphertext memory _cipher) external returns (uint256) {
        uint256 id = newCipherId();
        emit NewCiphertext(id, _cipher.random.x, _cipher.random.y, _cipher.cipher, msg.sender);
        return id;
    }

    // TODO payable etc
    // the public key is the public key of the recipient. Note the msg.sender
    // MUST be the one that submitted the ciphertext in the first place
    // otherwise the oracle will not reply
    function requestReencryption(uint256 _cipher_id, Bn128.G1Point memory _publickey) public returns (uint256) {
        // TODO check correct key
        uint256 request_id = newRequestId();
        pending_requests[request_id] = PendingRequest(msg.sender);
        emit ReencryptionRequest(_cipher_id, request_id, _publickey.x, _publickey.y, msg.sender);
        return request_id;
    }

    function requestDoExists(uint256 id) private view returns (bool) {
        PendingRequest memory pr = pending_requests[id];
        return pr.client != address(0);
    }

    // TODO cipher is not strictly required given that's the part that _doesn't_
    // change, although we probably dont want to store it onchain? but then we
    // can't guarantee it's for the same, we have to "trust" the oracle  --
    // probably zkproofs are sufficient to guarantee this once implemented
    function deliverReencryption(uint256 _request_id, IEncryptionOracle.Ciphertext memory _cipher) public {
        // TODO check that sender is authorized
        require(requestDoExists(_request_id));
        PendingRequest memory pr = pending_requests[_request_id];
        delete(pending_requests[_request_id]);
        IEncryptionClient client = IEncryptionClient(pr.client);
        client.oracleResult(_request_id, _cipher);
    }

    function distributedKey() external view returns (Bn128.G1Point memory) {
        return distKey;
    }
}
