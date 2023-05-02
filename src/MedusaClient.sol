// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {
    IEncryptionOracle,
    Ciphertext,
    ReencryptedCipher
} from "./interfaces/IEncryptionOracle.sol";
import {IEncryptionClient} from "./interfaces/IEncryptionClient.sol";
import {G1Point} from "./Bn128.sol";

error CallbackNotAuthorized();

abstract contract MedusaClient is IEncryptionClient {
    IEncryptionOracle public oracle;

    modifier onlyOracle() {
        if (msg.sender != address(oracle)) {
            revert CallbackNotAuthorized();
        }
        _;
    }

    constructor(IEncryptionOracle _oracle) {
        oracle = _oracle;
    }

    function oracleResult(uint256 requestId, ReencryptedCipher calldata cipher)
        external
        onlyOracle
    {
        processOracleResult(requestId, cipher);
    }

    function processOracleResult(
        uint256 requestId,
        ReencryptedCipher memory cipher
    ) internal virtual;
}
