// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "./DkgManager.sol";

interface IEncryptionClient {
    function isAuthorized(uint256 id, uint256 publickey, uint256[] memory extra) external returns (bool);
    function oracleResult(uint256 id, uint256 r, uint256 cipher, uint256 publickey) external ;
}

interface IEncryptionOracle {
    function requestReencryption(uint256 id, uint256 publickey) external; 
    function submitCiphertext(uint256 r, uint256 cipher, uint256[] memory extra) external returns (uint256);
}

contract EncryptionOracle is DKGManager, IEncryptionOracle {

    // TODO authorization
    // who are the oracles sender that are allowed to push results
    //mapping(address => bool) authorized_oracle;
    address public authorized_client;

    struct PendingRequest {
        address client;
        uint256 publickey;
    }
    // pending request is used to track the reencryption requests, to make sure
    // the medusa node callsback the same contract that submitted the request in
    // the first place.
    mapping(uint256 => PendingRequest) pending_requests;
    uint256 private nonce_id = 0;

    // id: unique identifier of the ciphertext
    // publickey: recipient for which we wish to reencrypt for
    // client: inserted such that medusa nodes check the client that originated
    // the newciphertext event, is the same that request the reencryptionrequest
    event ReencryptionRequest(uint256 indexed id, uint256 publickey, address client);
    
    // id: newly created id for this ciphertext
    // r,cipher: random part of the ciphertext and then the "hashed"/encryption part of it
    // client: who is submitting this ciphertext to the logs
    // extra: any extra data to submit for this ciphertext. Medusa nodes will
    // give these extra data when they check locally that the
    // client.isAuthorized(.... extra) returns true.
    event NewCiphertext(uint256 indexed id, uint256 r, uint256 cipher, address client, uint256[] extra);

    function newId() private returns (uint256) {
        nonce_id += 1;
        return nonce_id;
    }
    
    function submitCiphertext(uint256 r, uint256 cipher, uint256[] memory extra) external returns (uint256) { 
        uint256 id = newId();
        emit NewCiphertext(id, r, cipher, msg.sender, extra);
        return id;
    }

    // TODO payable etc
    function requestReencryption(uint256 id, uint256 publickey) public {
        // TODO that prevents having multiple requests for same id -> make a
        // linked list
        require(requestDoNotExists(id),"requests already exists");
        pending_requests[id] = PendingRequest(msg.sender, publickey);
        emit ReencryptionRequest(id, publickey, msg.sender);
    }

    function requestDoNotExists(uint256 id) private view returns (bool) {
        PendingRequest memory pr = pending_requests[id];
        return pr.client == address(0) && pr.publickey == 0;
    }

    function requestDoExists(uint256 id) private view returns (bool) {
        PendingRequest memory pr = pending_requests[id];
        return pr.client != address(0) && pr.publickey != 0;
    }

    // TODO cipher is not strictly required given that's the part that _doesn't_
    // change, although we probably dont want to store it onchain? but then we
    // can't guarantee it's for the same, we have to "trust" the oracle  -- 
    // Check with zkproofs if they are sufficient to guarantee this
    function deliverReencryption(uint256 id, uint256 r, uint256 cipher) public {
        // TODO
        // 1. check that sender is authorized
        require(requestDoExists(id));
        PendingRequest memory pr = pending_requests[id];
        delete(pending_requests[id]);
        IEncryptionClient client = IEncryptionClient(pr.client);
        client.oracleResult(id, r, cipher, pr.publickey);
    }
}
