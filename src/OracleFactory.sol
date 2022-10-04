// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BN254EncryptionOracle} from "./BN254EncryptionOracle.sol";
import {EncryptionOracle} from "./EncryptionOracle.sol";
import {G1Point} from "./Bn128.sol";

/// @notice An enum of supported encryption suites
/// @dev The format is CURVE_KEYGROUP_ENCRYPTION
enum Suite {BN254_KEYG1_HGAMAL}

error UnsupportedSuite();

/// @title OracleFactory
/// @author Cryptonet
/// @notice Factory contract for creating encryption oracles
/// @dev Deploys new oracles with a specified distributed key and encryption suite
/// @dev The factory contract is the owner of all oracles it deploys
contract OracleFactory is Ownable {
    /// @notice Mapping from oracle ID to oracle address
    mapping(bytes32 => address) public oracles;

    /// @notice Emitted when a new oracle is deployed
    event NewOracleCreated(bytes32 id, address oracle);

    /// @notice Deploys a new oracle with the specified distributed key and encryption suite
    /// @dev Only the Factory owner can deploy a new oracle
    /// @param _distKey The distributed key previously created by a DKG process
    /// @param _suite The encryption suite to use
    /// @return The id and address of the new oracle
    function deployNewOracle(G1Point memory _distKey, Suite _suite) public onlyOwner returns (bytes32, address) {
        EncryptionOracle oracle;
        if (_suite == Suite.BN254_KEYG1_HGAMAL) {
            oracle = new BN254EncryptionOracle(_distKey);
        } else {
            revert UnsupportedSuite();
        }

        bytes32 oracleId = keccak256(abi.encode(block.chainid, address(oracle)));
        oracles[oracleId] = address(oracle);

        emit NewOracleCreated(oracleId, address(oracle));
        return (oracleId, address(oracle));
    }

    function pauseOracle(bytes32 _oracleId) public onlyOwner {
        EncryptionOracle oracle = EncryptionOracle(oracles[_oracleId]);
        oracle.pause();
    }

    function unpauseOracle(bytes32 _oracleId) public onlyOwner {
        EncryptionOracle oracle = EncryptionOracle(oracles[_oracleId]);
        oracle.unpause();
    }
}
