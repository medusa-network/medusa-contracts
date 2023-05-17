// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {BaseScript} from "./BaseScript.s.sol";
import {G1Point} from "../src/utils/Bn128.sol";
import {Suite} from "../src/interfaces/IEncryptionOracle.sol";
import {BN254EncryptionOracle} from "../src/BN254EncryptionOracle.sol";
import {OracleFactory} from "../src/OracleFactory.sol";
import {ScriptReturns} from "./types/ScriptReturns.sol";

contract DeployBN254EncryptionOracle is BaseScript {
    G1Point private distKey = getDistributedKey();
    address private relayer = getNodes()[0];
    OracleFactory private factory = getOracleFactory();
    uint96 private submissionFee = uint96(vm.envUint("SUBMISSION_FEE"));
    uint96 private reencryptionFee = uint96(vm.envUint("REENCRYPTION_FEE"));

    ScriptReturns.DeployBN254EncryptionOracle private contracts;

    function run()
        external
        returns (ScriptReturns.DeployBN254EncryptionOracle memory)
    {
        contracts = deploy(factory, salt);
        assertions();
        return contracts;
    }

    function deploy(OracleFactory _factory, bytes32 _salt)
        public
        broadcaster
        returns (ScriptReturns.DeployBN254EncryptionOracle memory _contracts)
    {
        _contracts.impl = new BN254EncryptionOracle();

        address proxy = _factory.deployDeterministicAndCall(
            address(_contracts.impl),
            deployer,
            _salt,
            abi.encodeWithSelector(
                BN254EncryptionOracle.initialize.selector,
                distKey,
                deployer,
                relayer,
                submissionFee,
                reencryptionFee
            )
        );

        _contracts.oracle = BN254EncryptionOracle(proxy);
        return _contracts;
    }

    function assertions() private view {
        require(contracts.oracle.distributedKey().x == distKey.x);
        require(contracts.oracle.distributedKey().y == distKey.y);
        require(contracts.oracle.owner() == deployer);
        require(contracts.oracle.relayer() == relayer);
        require(contracts.oracle.submissionFee() == submissionFee);
        require(contracts.oracle.reencryptionFee() == reencryptionFee);
        require(contracts.oracle.suite() == Suite.BN254_KEYG1_HGAMAL);
    }
}
