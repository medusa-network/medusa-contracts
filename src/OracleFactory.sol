// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BN254EncryptionOracle} from "./BN254EncryptionOracle.sol";
import {EncryptionOracle} from "./EncryptionOracle.sol";
import {G1Point} from "./Bn128.sol";

/// @title OracleFactory
/// @author Cryptonet
/// @notice Factory contract for creating encryption oracles
/// @dev Deploys new oracles with a specified distributed key and encryption suite
/// @dev The factory contract is the owner of all oracles it deploys
contract OracleFactory is Ownable {
    /// @notice List of running oracles
    mapping(address => bool) public oracles;

    /// @notice Emitted when a new oracle is deployed
    event NewReencryption_BN254_G1_HGAMAL(address oracle);

    /// @notice Deploys a new oracle with the specified distributed key and encryption suite
    /// @dev Only the Factory owner can deploy a new oracle
    /// @param _distKey The distributed key previously created by a DKG process
    /// @return The id and address of the new oracle
    function deployReencryption_BN254_G1_HGAMAL(G1Point calldata _distKey) external onlyOwner returns (address) {
        EncryptionOracle oracle;
        oracle = new BN254EncryptionOracle(_distKey);

        oracles[address(oracle)] = true;

        emit NewReencryption_BN254_G1_HGAMAL(address(oracle));
        return address(oracle);
    }

    function pauseOracle(address _oracle) public onlyOwner {
        require(oracles[_oracle], "no oracle at this address registered");
        EncryptionOracle oracle = EncryptionOracle(_oracle);
        oracle.pause();
    }

    function unpauseOracle(address _oracle) public onlyOwner {
        require(oracles[_oracle], "no oracle at this address registered");
        EncryptionOracle oracle = EncryptionOracle(_oracle);
        oracle.unpause();
    }
}
