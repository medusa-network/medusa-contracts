// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {IThresholdNetwork} from "../DKG.sol";
import {G1Point, DleqProof} from "../Bn128.sol";

/// @notice An enum of supported encryption suites
/// @dev The format is CURVE_KEYGROUP_ENCRYPTION
enum Suite {BN254_KEYG1_HGAMAL}

/// @notice A 32-byte encrypted ciphertext that a client submits to Medusa
struct Ciphertext {
    G1Point random;
    uint256 cipher;
    /// DLEQ part
    G1Point random2;
    DleqProof dleq;
}

/// @notice Struct that Medusa nodes submits in response to a request
struct ReencryptedCipher {
    G1Point random;
}

/// @notice A pending reencryption request
/// @dev client client's address to callback with a response
/// @dev fee the amount of native currency paid to cover reencryption fee and reimburse the relayer for gas
struct PendingRequest {
    address client; // 20 bytes ---------- 32 bytes packed; the entire struct fits in 1 storage slot
    uint96 fee; //     12 bytes          |
}

interface IEncryptionOracle is IThresholdNetwork {
    function pendingRequests(uint256 _requestId)
        external
        returns (address, uint96);

    function requestReencryption(uint256 _cipherId, G1Point calldata _publickey)
        external
        payable
        returns (uint256);

    /// @notice submit a ciphertext and has been created by the encryptor address.
    /// The ciphertext proof is checked and if correct, will be signalled to Medusa.
    function submitCiphertext(Ciphertext calldata _cipher, address _encryptor)
        external
        payable
        returns (uint256);

    function deliverReencryption(
        uint256 _requestId,
        ReencryptedCipher calldata _cipher
    ) external returns (bool);

    function estimateDeliverReencryption(
        uint256 _requestId,
        ReencryptedCipher calldata _cipher,
        address callbackRecipient
    ) external payable returns (bool);

    /// @notice All instance contracts must implement their own encryption suite
    /// @dev e.g. BN254_KEYG1_HGAMAL
    /// @return suite of curve + encryption params supported by this contract
    function suite() external pure returns (Suite);

    /// @notice Emitted when a new cipher text is registered with medusa
    /// @dev Broadcasts the id, cipher text, and client or owner of the cipher text
    event NewCiphertext(
        uint256 indexed id, Ciphertext ciphertext, address client
    );

    /// @notice Emitted when a new request is sent to medusa
    /// @dev Requests can be sent by clients that do not own the cipher text; must verify the request off-chain
    event ReencryptionRequest(
        uint256 indexed cipherId,
        uint256 requestId,
        G1Point publicKey,
        PendingRequest request
    );
}
