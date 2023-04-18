// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {IEncryptionOracle, Ciphertext, ReencryptedCipher} from "./interfaces/IEncryptionOracle.sol";
import {IEncryptionClient} from "./interfaces/IEncryptionClient.sol";
import {G1Point} from "./Bn128.sol";

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
