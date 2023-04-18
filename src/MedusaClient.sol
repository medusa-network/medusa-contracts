// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {IEncryptionOracle, Ciphertext, ReencryptedCipher} from "./EncryptionOracle.sol";
import {G1Point} from "./Bn128.sol";

interface IEncryptionClient {
    /// @notice Callback to client contract when medusa posts a result
    /// @dev Implement in client contracts of medusa
    /// @param requestId The id of the original request
    /// @param _cipher the reencryption result
    function oracleResult(uint256 requestId, ReencryptedCipher calldata _cipher)
        external;
}

abstract contract MedusaClient is IEncryptionClient {
    IEncryptionOracle public oracle;

    constructor(IEncryptionOracle _oracle) {
        oracle = _oracle;
    }

    function estimateGasForDeliverReencryption() external returns (bool) {
        uint256 requestId = oracle.requestReencryption(1, G1Point(1, 1));
        return
            oracle.deliverReencryption(
                requestId,
                ReencryptedCipher(G1Point(1, 1), 1)
            );
    }
}
