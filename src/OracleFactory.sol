// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IEncryptionOracle, Suite} from "./interfaces/IEncryptionOracle.sol";
import {EncryptionOracle} from "./EncryptionOracle.sol";
import {BN254EncryptionOracle} from "./BN254EncryptionOracle.sol";
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
    event NewOracleDeployed(address oracle, Suite suite);

    /// @notice Deploys a new oracle with the specified distributed key and encryption suite
    /// @dev Only the Factory owner can deploy a new oracle
    /// @param _distKey The distributed key previously created by a DKG process
    /// @return The id and address of the new oracle
    function deployReencryption_BN254_G1_HGAMAL(
        G1Point calldata _distKey,
        address _relayer,
        uint96 _submissionFee,
        uint96 _reencryptionFee
    ) external onlyOwner returns (address) {
        BN254EncryptionOracle oracle = new BN254EncryptionOracle(
            _distKey,
            _relayer,
            _submissionFee,
            _reencryptionFee
        );

        oracles[address(oracle)] = true;

        emit NewOracleDeployed(address(oracle), Suite.BN254_KEYG1_HGAMAL);
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

    function updateRelayer(address _oracle, address _newRelayer)
        public
        onlyOwner
    {
        require(oracles[_oracle], "no oracle at this address registered");
        EncryptionOracle oracle = EncryptionOracle(_oracle);
        oracle.updateRelayer(_newRelayer);
    }

    function updateSubmissionFee(address _oracle, uint96 _submissionFee)
        public
        onlyOwner
    {
        require(oracles[_oracle], "no oracle at this address registered");
        EncryptionOracle oracle = EncryptionOracle(_oracle);
        oracle.updateSubmissionFee(_submissionFee);
    }

    function updateReencryptionFee(address _oracle, uint96 _reencryptionFee)
        public
        onlyOwner
    {
        require(oracles[_oracle], "no oracle at this address registered");
        EncryptionOracle oracle = EncryptionOracle(_oracle);
        oracle.updateReencryptionFee(_reencryptionFee);
    }
}
