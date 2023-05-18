// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {Ownable} from "solady/auth/Ownable.sol";
import {IDKGMembership} from "./interfaces/IDKGMembership.sol";

/// @title PermissionedDKGMembership
/// @notice Owned contract for managing authorized nodes to participate in DKGs
contract PermissionedDKGMembership is Ownable, IDKGMembership {
    /// @notice Mapping of authorized node addresses
    mapping(address => bool) private authorizedNodes;

    constructor(address owner) {
        _initializeOwner(owner);
    }

    // @notice implementing IDKGMembership interface
    function isAuthorizedNode(address node) external view returns (bool) {
        return authorizedNodes[node];
    }

    function addAuthorizedNode(address node) external onlyOwner {
        authorizedNodes[node] = true;
    }

    function removeAuthorizedNode(address node) external onlyOwner {
        delete authorizedNodes[node];
    }
}
