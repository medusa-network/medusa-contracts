// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {G1Point} from "../utils/Bn128.sol";
import {IThresholdNetwork} from "./IThresholdNetwork.sol";

enum ComplaintReturn {
    ValidComplaint,
    InvalidDealerIdx,
    InvalidHash,
    InvalidDleq,
    InvalidConsistentShare
}

/// @notice A bundle of deals submitted by each participant.
struct DealBundle {
    uint256[] encryptedShares;
    G1Point[] commitment;
}

interface IDKG is IThresholdNetwork {
    enum Phase {
        REGISTRATION,
        DEAL,
        COMPLAINT,
        DONE
    }

    /// @notice Emitted when a new participant registers during the registration phase.
    /// @param from The address of the participant.
    /// @param index The index of the participant.
    /// @param tmpKey The temporary key of the participant.
    event NewParticipant(address from, uint32 index, G1Point tmpKey);

    /// @notice Emitted when a deal is submitted during the deal phase.
    /// @param dealerIdx The index of the dealer submitting the deal.
    /// @param bundle The deal bundle submitted by the dealer.
    event DealBundleSubmitted(uint32 dealerIdx, DealBundle bundle);

    /// @notice Emitted when a participant is evicted from the protocol. It can
    /// happen during any phases.
    /// @param from The address of the participant who got evicted
    /// @param index The index of the participant who is evicted from the network.
    event EvictedParticipant(address from, uint32 index);
}
