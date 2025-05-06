// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {Initializable} from
    "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Suite} from "../src/interfaces/IEncryptionOracle.sol";
import {EncryptionOracle} from "./EncryptionOracle.sol";
import {G1Point} from "./utils/Bn128.sol";

contract BN254EncryptionOracle is Initializable, EncryptionOracle {
    function initialize(
        G1Point memory _distKey,
        address _owner,
        address _relayer,
        uint96 _submissionFee,
        uint96 _reencryptionFee
    ) public initializer {
        EncryptionOracle._initialize(
            _distKey, _owner, _relayer, _submissionFee, _reencryptionFee
        );
    }

    function suite() external pure override returns (Suite) {
        return Suite.BN254_KEYG1_HGAMAL;
    }
}
