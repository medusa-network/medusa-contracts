// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {DKGFactory} from "../../src/DKGFactory.sol";
import {OracleFactory} from "../../src/OracleFactory.sol";
import {DKG} from "../../src/DKG.sol";
import {BN254EncryptionOracle} from "../../src/BN254EncryptionOracle.sol";
import {OnlyFiles} from "../../src/client/OnlyFiles.sol";

library ScriptReturns {
    struct DeployFactories {
        DKGFactory dkgFactory;
        OracleFactory oracleFactory;
        address[] nodes;
    }

    struct DeployDKG {
        DKG dkg;
    }

    struct DeployBN254EncryptionOracle {
        BN254EncryptionOracle impl;
        BN254EncryptionOracle oracle;
    }

    struct DeployOnlyFiles {
        OnlyFiles onlyFiles;
    }
}
