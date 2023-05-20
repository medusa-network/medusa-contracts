// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {Initializable} from
    "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IThresholdNetwork} from "./interfaces/IThresholdNetwork.sol";
import {G1Point} from "./utils/Bn128.sol";

/// @title ThresholdNetwork
/// @author Cryptonet
/// @notice This contract represents a threshold network.
/// @dev All threshold networks have a distributed key;
/// the DKG contract facilitates the generation of a key, whereas Oracle contracts are given a key
abstract contract ThresholdNetworkUpgradeable is
    Initializable,
    IThresholdNetwork
{
    G1Point internal distKey;

    function _initialize(G1Point memory _distKey) internal onlyInitializing {
        distKey = _distKey;
    }

    function distributedKey() external view virtual returns (G1Point memory) {
        return distKey;
    }
}
