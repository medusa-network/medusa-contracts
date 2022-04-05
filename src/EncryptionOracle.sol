// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "./DkgManager.sol";

interface IEncryptionClient {
    function isAuthorized(uint256 cipher_id, uint256 publickey, uint256[] memory extra) external returns (bool);
    function oracleResult(uint256 cipher_id, uint256 request_id, uint256 r, uint256 cipher, uint256 publickey) external ;
}

interface IEncryptionOracle {
    // returns the request id
    function requestReencryption(uint256 _cipher_id, uint256 _publickey) external returns (uint256); 
    // returns the ciphertext id
    function submitCiphertext(uint256 _r, uint256 _cipher, uint256[] memory _extra) external returns (uint256);
}

contract EncryptionOracle is DKGManager, IEncryptionOracle {

    // TODO authorization
    // who are the oracles sender that are allowed to push results
    //mapping(address => bool) authorized_oracle;
    address public authorized_client;

    struct PendingRequest {
        address client;
        uint256 publickey;
        uint256 cipher_id;
    }
    // pending request is used to track the reencryption requests, to make sure
    // the medusa node callsback the same contract that submitted the request in
    // the first place.
    mapping(uint256 => PendingRequest) pending_requests;
    // counter to derive unique nonces for each ciphertext ever submitted to the oracle
    uint256 private cipher_nonce = 0;
    // counter to derive unique nonces for each reencryption request ever submitted to the oracle
    uint256 private request_nonce = 0;

    // id: unique identifier of the ciphertext
    // publickey: recipient for which we wish to reencrypt for
    // client: inserted such that medusa nodes check the client that originated
    // the newciphertext event, is the same that request the reencryptionrequest
    event ReencryptionRequest(uint256 indexed cipher_id, uint256 request_id, uint256 publickey, address client);
    
    // id: newly created id for this ciphertext
    // r,cipher: random part of the ciphertext and then the "hashed"/encryption part of it
    // client: who is submitting this ciphertext to the logs
    // extra: any extra data to submit for this ciphertext. Medusa nodes will
    // give these extra data when they check locally that the
    // client.isAuthorized(.... extra) returns true.
    event NewCiphertext(uint256 indexed id, uint256 r, uint256 cipher, address client, uint256[] extra);

    function newCipherId() private returns (uint256) {
        cipher_nonce += 1;
        return cipher_nonce;
    }

    function newRequestId() private returns (uint256) {
        request_nonce += 1;
        return request_nonce;
    }
    
    function submitCiphertext(uint256 _r, uint256 _cipher, uint256[] memory _extra) external returns (uint256) { 
        uint256 id = newCipherId();
        emit NewCiphertext(id, _r, _cipher, msg.sender, _extra);
        return id;
    }

    // TODO payable etc
    function requestReencryption(uint256 _cipher_id, uint256 _publickey) public returns (uint256) {
        uint256 request_id = newRequestId();
        pending_requests[request_id] = PendingRequest(msg.sender, _publickey, _cipher_id);
        emit ReencryptionRequest(_cipher_id, request_id, _publickey, msg.sender);
        return request_id;
    }

    function requestDoExists(uint256 id) private view returns (bool) {
        PendingRequest memory pr = pending_requests[id];
        return pr.client != address(0) && pr.publickey != 0;
    }

    // TODO cipher is not strictly required given that's the part that _doesn't_
    // change, although we probably dont want to store it onchain? but then we
    // can't guarantee it's for the same, we have to "trust" the oracle  -- 
    // Check with zkproofs if they are sufficient to guarantee this
    function deliverReencryption(uint256 _request_id, uint256 r, uint256 cipher) public {
        // TODO
        // 1. check that sender is authorized
        require(requestDoExists(_request_id));
        PendingRequest memory pr = pending_requests[_request_id];
        delete(pending_requests[_request_id]);
        IEncryptionClient client = IEncryptionClient(pr.client);
        client.oracleResult(pr.cipher_id, pr.cipher_id, r, cipher, pr.publickey);
    }
}
