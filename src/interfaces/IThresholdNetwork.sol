// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {G1Point} from "../utils/Bn128.sol";

interface IThresholdNetwork {
    function distributedKey() external view returns (G1Point memory);
}
