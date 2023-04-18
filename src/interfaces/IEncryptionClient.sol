// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {ReencryptedCipher} from "../EncryptionOracle.sol";

interface IEncryptionClient {
    /// @notice Callback to client contract when medusa posts a result
    /// @dev Implement in client contracts of medusa
    /// @param requestId The id of the original request
    /// @param _cipher the reencryption result
    function oracleResult(uint256 requestId, ReencryptedCipher calldata _cipher)
        external;
}
