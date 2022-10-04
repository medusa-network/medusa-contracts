// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DKG} from "./DKG.sol";

/// @title DKGFactory
/// @author Cryptonet
/// @notice Factory contract for creating DKGs
/// @dev Deploys new DKGs and registers a unique id for each
contract DKGFactory is Ownable {
    /// @notice Mapping of DKG ID to DKG address
    mapping(bytes32 => address) public dkgAddresses;

    /// @notice Mapping of authorized node addresses
    mapping(address => bool) public authorizedNodes;

    /// @notice Emitted when a new DKG is deployed
    /// @param id The unique id of the DKG
    /// @param dkg The address of the deployed DKG
    event NewDKGCreated(bytes32 id, address dkg);

    /// @notice Deploys a new DKG
    /// @dev Only the Factory owner can deploy a new DKG
    /// @return The id and address of the new DKG
    function deployNewDKG() public onlyOwner returns (bytes32, address) {
        DKG dkg = new DKG(this);
        bytes32 dkgId = keccak256(abi.encode(block.chainid, address(dkg)));
        dkgAddresses[dkgId] = address(dkg);

        emit NewDKGCreated(dkgId, address(dkg));
        return (dkgId, address(dkg));
    }

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
