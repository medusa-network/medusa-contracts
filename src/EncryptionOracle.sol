// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ThresholdNetwork} from "./DKG.sol";
import {Bn128, G1Point, DleqProof} from "./Bn128.sol";
import {
    IEncryptionOracle,
    Ciphertext,
    ReencryptedCipher,
    PendingRequest,
    Suite
} from "./interfaces/IEncryptionOracle.sol";
import {IEncryptionClient} from "./interfaces/IEncryptionClient.sol";

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

/// @notice Reverts when the oracleFee is not paid for ciphertext submission and reencryption
error InsufficientFunds();

/// @title An abstract EncryptionOracle that receives requests and posts results for reencryption
/// @notice You must implement your encryption suite when inheriting from this contract
/// @dev DOES NOT currently validate reencryption results OR implement fees for the medusa oracle network
abstract contract EncryptionOracle is
    ThresholdNetwork,
    IEncryptionOracle,
    Ownable,
    Pausable
{
    /// @notice relayer that is trusted to deliver reencryption results
    address public relayer; // 20 bytes -- 32 bytes packed with oracleFee
    /// @notice fee paid for ciphertext submission
    uint96 public submissionFee; // 12 bytes -- 32 bytes packed with relayer; fees are also packed with callback address in PendingRequest

    /// @notice fee paid for reencryption requests
    uint96 public reencryptionFee;

    /// @notice pendingRequests tracks the reencryption requests
    /// @dev We use this to determine the client to callback with the result and to store the gas reimbursement paid by the client
    mapping(uint256 requestId => PendingRequest pendingRequest) public
        pendingRequests;

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

    modifier feePaid(uint96 _fee) {
        if (msg.value < _fee) {
            revert InsufficientFunds();
        }
        _;
    }

    /// @notice Create a new oracle contract with a distributed public key
    /// @dev The distributed key is created by an on-chain DKG process
    /// @dev Verify the key by checking all DKG contracts deployed by Medusa operators
    /// @param _distKey An (x, y) point on an elliptic curve representing a public key previously created by medusa nodes
    /// @param _relayer that is trusted to deliver reencryption results
    /// @param _submissionFee for submitCiphertext()
    /// @param _reencryptionFee for requestReencryption()
    constructor(
        G1Point memory _distKey,
        address _relayer,
        uint96 _submissionFee,
        uint96 _reencryptionFee
    ) ThresholdNetwork(_distKey) {
        relayer = _relayer;
        submissionFee = _submissionFee;
        reencryptionFee = _reencryptionFee;
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
        payable
        whenNotPaused
        feePaid(submissionFee)
        returns (uint256)
    {
        uint256 label = uint256(
            sha256(
                abi.encodePacked(distKey.x, distKey.y, msg.sender, _encryptor)
            )
        );
        if (
            !Bn128.dleqverify(
                _cipher.random, _cipher.random2, _cipher.dleq, label
            )
        ) {
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
        feePaid(reencryptionFee)
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
    function deliverReencryption(
        uint256 _requestId,
        ReencryptedCipher calldata _cipher
    ) external whenNotPaused onlyRelayer returns (bool) {
        PendingRequest memory pr = pendingRequests[_requestId];
        if (pr.client == address(0)) {
            revert RequestDoesNotExist();
        }
        delete pendingRequests[_requestId];

        return deliverCallback(_requestId, _cipher, pr);
    }

    /// @notice Used to estimate gas for a callback before a request has been sent
    /// @param _requestId the pending request id; used to callback the correct client
    /// @param _cipher The reencryption result for the request
    /// @param callbackRecipient Address of client contract to simulate the call against
    /// @return true if the client callback succeeds, otherwise reverts with OracleResultFailed
    function estimateDeliverReencryption(
        uint256 _requestId,
        ReencryptedCipher calldata _cipher,
        address callbackRecipient
    )
        external
        payable
        whenNotPaused
        onlyRelayer
        feePaid(reencryptionFee)
        returns (bool)
    {
        PendingRequest memory pr = pendingRequests[_requestId];
        if (pr.client != address(0)) {
            delete pendingRequests[_requestId];
        } else {
            pr.client = callbackRecipient;
        }

        return deliverCallback(_requestId, _cipher, pr);
    }

    /// @notice The relayer withdraws all fees accumulated
    function withdrawFees() external whenNotPaused onlyRelayer returns (bool) {
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        return sent;
    }

    /// @notice The relayer or owner updates the relayer address
    /// @param _newRelayer The address of the new relayer
    function updateRelayer(address _newRelayer)
        external
        whenNotPaused
        onlyRelayerOrOwner
    {
        relayer = _newRelayer;
    }

    /// @notice The owner updates the submissionFee
    /// @param _submissionFee The new submissionFee
    function updateSubmissionFee(uint96 _submissionFee)
        external
        whenNotPaused
        onlyOwner
    {
        submissionFee = _submissionFee;
    }

    /// @notice The owner updates the reencryptionFee
    /// @param _reencryptionFee The new reencryptionFee
    function updateReencryptionFee(uint96 _reencryptionFee)
        external
        whenNotPaused
        onlyOwner
    {
        reencryptionFee = _reencryptionFee;
    }

    /// @notice Pays the relayer and delivers the callback to the client
    /// @param requestId the pending request id; used to callback the correct client
    /// @param cipher The reencryption result for the request
    /// @param pr The PendingRequest with client address to call
    /// @return true if the client callback succeeds, otherwise reverts with OracleResultFailed
    function deliverCallback(
        uint256 requestId,
        ReencryptedCipher memory cipher,
        PendingRequest memory pr
    ) private returns (bool) {
        IEncryptionClient client = IEncryptionClient(pr.client);

        // Note: This should be safe from reentrancy attacks because we delete the pending request before paying/calling the relayer
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        if (!sent) {
            revert OracleResultFailed("Failed to send gas reimbursement");
        }

        try client.oracleResult(requestId, cipher) {
            return true;
        } catch Error(string memory reason) {
            revert OracleResultFailed(reason);
        } catch {
            revert OracleResultFailed(
                "Client does not support oracleResult() method"
            );
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
}
