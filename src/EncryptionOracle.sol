// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "./DkgManager.sol";

interface IEncryptionClient {
    function oracleResult(uint256 id, uint256 r, uint256 cipher) external ;
}

interface IEncryptionOracle {
    function requestReencryption(uint256 r, uint256 cipher,uint256 publickey) external; 
}

contract EncryptionOracle is DKGManager, IEncryptionOracle {

    // TODO authorization
    // who are the oracles sender that are allowed to push results
    //mapping(address => bool) authorized_oracle;
    address public authorized_client;
    uint256 nonce_id = 0;
    mapping(uint256 => address) pending_requests;

    event ReencryptionRequest(uint256 indexed id, uint256 publickey,uint256 r, uint256 cipher);
    
    // TODO payable etc
    function requestReencryption(uint256 r, uint256 cipher,uint256 publickey) public {
        // TODO 
        // 0. check msg.sender comes from valid users
        // 1. check publickey is valid
        // 2. check enough money
        nonce_id += 1;
        pending_requests[nonce_id] = msg.sender;
        emit ReencryptionRequest(nonce_id, publickey, r, cipher);
    }

    // TODO cipher is not strictly required given that's the part that _doesn't_
    // change, although we probably dont want to store it onchain? but then we
    // can't guarantee it's for the same, we have to "trust" the oracle  -- 
    // Check with zkproofs if they are sufficient to guarantee this
    function deliverReencryption(uint256 id, uint256 r, uint256 cipher) public {
        // TODO
        // 1. check that sender is authorized
        require(pending_requests[id] != address(0),"unknown reencryption request"); 
        address addr = pending_requests[id];
        delete(pending_requests[id]);
        IEncryptionClient client = IEncryptionClient(addr);
        client.oracleResult(id, r, cipher);
    }
}
