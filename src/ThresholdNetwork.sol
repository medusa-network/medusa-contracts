// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {IThresholdNetwork} from "./interfaces/IThresholdNetwork.sol";
import {G1Point} from "./utils/Bn128.sol";

/// @title ThresholdNetwork
/// @author Cryptonet
/// @notice This contract represents a threshold network.
/// @dev All threshold networks have a distributed key;
/// the DKG contract facilitates the generation of a key, whereas Oracle contracts are given a key
abstract contract ThresholdNetwork is IThresholdNetwork {
    G1Point internal distKey;

    constructor(G1Point memory _distKey) {
        distKey = _distKey;
    }

    function distributedKey() external view virtual returns (G1Point memory) {
        return distKey;
    }
}
