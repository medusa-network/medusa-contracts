// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {Ownable} from "solady/auth/Ownable.sol";
import {DKG} from "./DKG.sol";
import {IDKGMembership} from "./interfaces/IDKGMembership.sol";

/// @title DKGManager
/// @author Cryptonet
/// @notice Contract to alert nodes of new DKGs
contract DKGManager is Ownable {
    /// @notice Emitted when a new DKG is registered
    /// @param dkg The address of the deployed DKG
    event NewDKGCreated(address dkg);

    constructor(address owner) {
        _initializeOwner(owner);
    }

    /// @notice Alerts nodes of new DKGs with by emitting an event
    /// @dev Only the owner can register a new DKG
    function registerNewDKG(DKG dkg) external onlyOwner {
        emit NewDKGCreated(address(dkg));
    }
}
