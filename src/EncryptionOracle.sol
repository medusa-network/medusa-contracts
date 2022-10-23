// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Suite} from "./OracleFactory.sol";
import {ThresholdNetwork} from "./DKG.sol";
import {Bn128, G1Point, DleqProof} from "./Bn128.sol";

/// @notice A 32-byte encrypted ciphertext
struct Ciphertext {
    G1Point random;
    uint256 cipher;
    /// DLEQ part
    G1Point random2;
    DleqProof dleq;
}

interface IEncryptionClient {
    /// @notice Callback to client contract when medusa posts a result
    /// @dev Implement in client contracts of medusa
    /// @param requestId The id of the original request
    /// @param _cipher the reencryption result
    function oracleResult(uint256 requestId, Ciphertext calldata _cipher) external;
}

interface IEncryptionOracle {
    function requestReencryption(uint256 _cipherId, G1Point calldata _publickey) external returns (uint256);

    /// @notice submit a ciphertext that can be retrieved at the given link and
    /// has been created by this encryptor address. The ciphertext proof is checked
    /// and if correct, being signalled to Medusa.
    function submitCiphertext(Ciphertext calldata _cipher, bytes calldata _link, address _encryptor)
        external
        returns (uint256);

    function deliverReencryption(uint256 _requestId, Ciphertext calldata _cipher) external returns (bool);

    /// @notice All instance contracts must implement their own encryption suite
    /// @dev e.g. BN254_KEYG1_HGAMAL
    /// @return suite of curve + encryption params supported by this contract
    function suite() external pure virtual returns (Suite);

    /// @notice Emitted when a new cipher text is registered with medusa
    /// @dev Broadcasts the id, cipher text, and client or owner of the cipher text
    event NewCiphertext(uint256 indexed id, Ciphertext ciphertext, bytes link, address client);

    /// @notice Emitted when a new request is sent to medusa
    /// @dev Requests can be sent by clients that do not own the cipher text; must verify the request off-chain
    event ReencryptionRequest(uint256 indexed cipherId, uint256 requestId, G1Point publicKey, address client);
}

/// @notice Reverts when delivering a response for a non-existent request
error RequestDoesNotExist();

/// @notice Reverts when the client's callback function reverts
error OracleResultFailed(string errorMsg);

/// @notice invalid ciphertext proof. This can happen when one submits a ciphertext
/// being made for one chainid, or for one smart contract  but is being submitted
/// to another.
error InvalidCiphertextProof();

/// @title An abstract EncryptionOracle that receives requests and posts results for reencryption
/// @notice You must implement your encryption suite when inheriting from this contract
/// @dev DOES NOT currently validate reencryption results OR implement fees for the medusa oracle network
abstract contract EncryptionOracle is ThresholdNetwork, IEncryptionOracle, Ownable, Pausable {
    /// @notice A pending reencryption request
    /// @dev client client's address to callback with a response
    struct PendingRequest {
        address client;
    }

    /// @notice pendingRequests tracks the reencryption requests
    /// @dev We use this to determine the client to callback with the result
    mapping(uint256 => PendingRequest) private pendingRequests;

    /// @notice counter to derive unique nonces for each ciphertext
    uint256 private cipherNonce = 0;

    /// @notice counter to derive unique nonces for each reencryption request
    uint256 private requestNonce = 0;

    /// @notice Create a new oracle contract with a distributed public key
    /// @dev The distributed key is created by an on-chain DKG process
    /// @dev Verify the key by checking all DKG contracts deployed by Medusa operators
    /// @notice The public key corresponding to the distributed private key registered for this contract
    /// @dev This is passed in by the OracleFactory. Corresponds to an x-y point on an elliptic curve
    /// @param _distKey An x-y point representing a public key previously created by medusa nodes
    constructor(G1Point memory _distKey) ThresholdNetwork(_distKey) {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Submit a new ciphertext and emit an event
    /// @dev We only emit an event; no storage. We authorize future requests for this ciphertext off-chain.
    /// @param _cipher The ciphertext of an encrypted key
    /// @param _link The link to the encrypted contents
    /// @return the id of the newly registered ciphertext
    function submitCiphertext(Ciphertext calldata _cipher, bytes calldata _link, address _encryptor)
        external
        whenNotPaused
        returns (uint256)
    {
        uint256 label = uint256(sha256(abi.encodePacked(distKey.x, distKey.y, msg.sender, _encryptor)));
        if (!Bn128.dleqverify(_cipher.random, _cipher.random2, _cipher.dleq, label)) {
            revert InvalidCiphertextProof();
        }
        uint256 id = newCipherId();
        emit NewCiphertext(id, _cipher, _link, msg.sender);
        return id;
    }

    /// @notice Request reencryption of a cipher text for a user
    /// @dev msg.sender must be The "owner" or submitter of the ciphertext or the oracle will not reply
    /// @param _cipherId the id of the ciphertext to reencrypt
    /// @param _publicKey the public key of the recipient
    /// @return the reencryption request id
    /// @custom:todo Payable; users pay for the medusa network somehow (oracle gas + platform fee)
    function requestReencryption(uint256 _cipherId, G1Point calldata _publicKey)
        external
        whenNotPaused
        returns (uint256)
    {
        /// @custom:todo check correct key
        uint256 requestId = newRequestId();
        pendingRequests[requestId] = PendingRequest(msg.sender);
        emit ReencryptionRequest(_cipherId, requestId, _publicKey, msg.sender);
        return requestId;
    }

    /// @notice Oracle delivers the reencryption result
    /// @dev Needs to verify the request, result and then callback to the client
    /// @param _requestId the pending request id; used to callback the correct client
    /// @param _cipher The reencryption result for the request
    /// @return true if the client callback succeeds, otherwise reverts with OracleResultFailed
    function deliverReencryption(uint256 _requestId, Ciphertext calldata _cipher)
        external
        whenNotPaused
        returns (bool)
    {
        /// @custom:todo We need to verify a threshold signature to verify the cipher result
        if (!requestExists(_requestId)) {
            revert RequestDoesNotExist();
        }
        PendingRequest memory pr = pendingRequests[_requestId];
        delete pendingRequests[_requestId];
        IEncryptionClient client = IEncryptionClient(pr.client);
        try client.oracleResult(_requestId, _cipher) {
            return true;
        } catch Error(string memory reason) {
            revert OracleResultFailed(reason);
        } catch {
            revert OracleResultFailed("Client does not support oracleResult() method");
        }
    }

    function newCipherId() private returns (uint256) {
        cipherNonce += 1;
        return cipherNonce;
    }

    function newRequestId() private returns (uint256) {
        requestNonce += 1;
        return requestNonce;
    }

    function requestExists(uint256 id) private view returns (bool) {
        PendingRequest memory pr = pendingRequests[id];
        return pr.client != address(0);
    }
}
