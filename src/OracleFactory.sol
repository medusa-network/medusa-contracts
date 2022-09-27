// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BN254EncryptionOracle} from "./BN254EncryptionOracle.sol";
import {EncryptionOracle} from "./EncryptionOracle.sol";
import {Bn128} from "./Bn128.sol";

error UnsupportedSuite();

contract OracleFactory is Ownable {
    mapping(bytes32 => address) public oracles;

    event NewOracleCreated(bytes32 id, address oracle);

    enum Suite {BN254_KEYG1_HGAMAL}

    function deployNewOracle(Bn128.G1Point memory _distKey, Suite _suite) public onlyOwner returns (bytes32, address) {
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
}
