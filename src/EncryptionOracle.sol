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

/// @notice A pending reencryption request
/// @dev client client's address to callback with a response
/// @dev gasReimbursement the amount of native currency to reimburse the relayer for gas to submit a result onchain
struct PendingRequest {
    address client; // 20 bytes ---------- 32 bytes packed; the entire struct fits in 1 storage slot
    uint96 gasReimbursement; // 12 bytes |
}

interface IEncryptionClient {
    /// @notice Callback to client contract when medusa posts a result
    /// @dev Implement in client contracts of medusa
    /// @param requestId The id of the original request
    /// @param _cipher the reencryption result
    function oracleResult(uint256 requestId, Ciphertext calldata _cipher) external;
}

interface IEncryptionOracle {
    function pendingRequests(uint256 _requestId) external returns (address, uint96);

    function requestReencryption(uint256 _cipherId, G1Point calldata _publickey) external payable returns (uint256);

    /// @notice submit a ciphertext and has been created by the encryptor address.
    /// The ciphertext proof is checked and if correct, will be signalled to Medusa.
    function submitCiphertext(Ciphertext calldata _cipher, address _encryptor) external returns (uint256);

    function deliverReencryption(uint256 _requestId, Ciphertext calldata _cipher) external returns (bool);

    /// @notice All instance contracts must implement their own encryption suite
    /// @dev e.g. BN254_KEYG1_HGAMAL
    /// @return suite of curve + encryption params supported by this contract
    function suite() external pure virtual returns (Suite);

    /// @notice Emitted when a new cipher text is registered with medusa
    /// @dev Broadcasts the id, cipher text, and client or owner of the cipher text
    event NewCiphertext(uint256 indexed id, Ciphertext ciphertext, address client);

    /// @notice Emitted when a new request is sent to medusa
    /// @dev Requests can be sent by clients that do not own the cipher text; must verify the request off-chain
    event ReencryptionRequest(uint256 indexed cipherId, uint256 requestId, G1Point publicKey, PendingRequest request);
}

/// @notice Reverts when delivering a response for a non-existent request
error RequestDoesNotExist();

/// @notice Reverts when the client's callback function reverts
error OracleResultFailed(string errorMsg);

/// @notice invalid ciphertext proof. This can happen when one submits a ciphertext
/// being made for one chainid, or for one smart contract  but is being submitted
/// to another.
error InvalidCiphertextProof();

/// @notice Reverts when an EOA who is not the relayer tries to deliver a reencryption result
error NotRelayer();
/// @notice Reverts when someone who is not the relayer or the owner tries to update the relayer
error NotRelayerOrOwner();

/// @title An abstract EncryptionOracle that receives requests and posts results for reencryption
/// @notice You must implement your encryption suite when inheriting from this contract
/// @dev DOES NOT currently validate reencryption results OR implement fees for the medusa oracle network
abstract contract EncryptionOracle is ThresholdNetwork, IEncryptionOracle, Ownable, Pausable {
    /// @notice relayer that is trusted to deliver reencryption results
    address public relayer;

    /// @notice pendingRequests tracks the reencryption requests
    /// @dev We use this to determine the client to callback with the result and to store the gas reimbursement paid by the client
    mapping(uint256 => PendingRequest) public pendingRequests;

    /// @notice counter to derive unique nonces for each ciphertext
    uint256 private cipherNonce = 0;

    /// @notice counter to derive unique nonces for each reencryption request
    uint256 private requestNonce = 0;

    modifier onlyRelayer() {
        if (msg.sender != relayer) revert NotRelayer();
        _;
    }

    modifier onlyRelayerOrOwner() {
        if (msg.sender != relayer && msg.sender != owner()) {
            revert NotRelayerOrOwner();
        }
        _;
    }

    /// @notice Create a new oracle contract with a distributed public key
    /// @dev The distributed key is created by an on-chain DKG process
    /// @dev Verify the key by checking all DKG contracts deployed by Medusa operators
    /// @param _distKey An (x, y) point on an elliptic curve representing a public key previously created by medusa nodes
    /// @param _relayer that is trusted to deliver reencryption results
    constructor(G1Point memory _distKey, address _relayer) ThresholdNetwork(_distKey) {
        relayer = _relayer;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Submit a new ciphertext and emit an event
    /// @dev We only emit an event; no storage. We authorize future requests for this ciphertext off-chain.
    /// @param _cipher The ciphertext of an encrypted key
    /// @return the id of the newly registered ciphertext
    function submitCiphertext(Ciphertext calldata _cipher, address _encryptor)
        external
        whenNotPaused
        returns (uint256)
    {
        uint256 label = uint256(sha256(abi.encodePacked(distKey.x, distKey.y, msg.sender, _encryptor)));
        if (!Bn128.dleqverify(_cipher.random, _cipher.random2, _cipher.dleq, label)) {
            revert InvalidCiphertextProof();
        }
        uint256 id = newCipherId();
        emit NewCiphertext(id, _cipher, msg.sender);
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
        payable
        whenNotPaused
        returns (uint256)
    {
        /// @custom:todo check correct key
        uint256 requestId = newRequestId();
        PendingRequest memory pr = PendingRequest(msg.sender, uint96(msg.value));
        pendingRequests[requestId] = pr;
        emit ReencryptionRequest(_cipherId, requestId, _publicKey, pr);
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
        onlyRelayer
        returns (bool)
    {
        /// @custom:todo We need to verify a threshold signature to verify the cipher result
        if (!requestExists(_requestId)) {
            revert RequestDoesNotExist();
        }
        PendingRequest memory pr = pendingRequests[_requestId];
        delete pendingRequests[_requestId];
        IEncryptionClient client = IEncryptionClient(pr.client);

        // Note: This should be safe from reentrancy attacks because we delete the pending request before paying/calling the relayer
        (bool sent,) = msg.sender.call{value: pr.gasReimbursement}("");
        if (!sent) {
            revert OracleResultFailed("Failed to send gas reimbursement");
        }

        try client.oracleResult(_requestId, _cipher) {
            return true;
        } catch Error(string memory reason) {
            revert OracleResultFailed(reason);
        } catch {
            revert OracleResultFailed("Client does not support oracleResult() method");
        }
    }

    /// @notice The relayer or owner updates the relayer address
    /// @param _newRelayer The address of the new relayer
    function updateRelayer(address _newRelayer) external whenNotPaused onlyRelayerOrOwner {
        relayer = _newRelayer;
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
