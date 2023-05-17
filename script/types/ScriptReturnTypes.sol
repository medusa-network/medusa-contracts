// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {DKGFactory} from "../../src/DKGFactory.sol";
import {OracleFactory} from "../../src/OracleFactory.sol";
import {DKG} from "../../src/DKG.sol";
import {EncryptionOracle} from "../../src/EncryptionOracle.sol";

struct DeployFactoriesReturn {
    DKGFactory dkgFactory;
    OracleFactory oracleFactory;
    address[3] nodes;
}

struct DeployDKGReturn {
    DKG dkg;
}

struct DeployOracleReturn {
    EncryptionOracle implementation;
    EncryptionOracle oracle;
}
