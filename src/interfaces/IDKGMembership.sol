// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

/// @notice An interface telling which addresses can participate to a DKG
interface IDKGMembership {
    function isAuthorizedNode(address participant)
        external
        view
        returns (bool);
}
