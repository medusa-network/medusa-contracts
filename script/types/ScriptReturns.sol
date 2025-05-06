// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {DKGManager} from "../../src/DKGManager.sol";
import {OracleFactory} from "../../src/OracleFactory.sol";
import {PermissionedDKGMembership} from
    "../../src/PermissionedDKGMembership.sol";
import {DKG} from "../../src/DKG.sol";
import {BN254EncryptionOracle} from "../../src/BN254EncryptionOracle.sol";
import {OnlyFiles} from "../../src/client/OnlyFiles.sol";

library ScriptReturns {
    struct DeployFactories {
        DKGManager dkgManager;
        OracleFactory oracleFactory;
    }

    struct DeployDKG {
        DKG dkg;
        PermissionedDKGMembership dkgMembership;
        address[] nodes;
    }

    struct DeployBN254EncryptionOracle {
        BN254EncryptionOracle impl;
        BN254EncryptionOracle oracle;
    }

    struct DeployOnlyFiles {
        OnlyFiles onlyFiles;
    }
}
