// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DKG} from "./DKG.sol";
import {Bn128} from "./Bn128.sol";

contract DKGFactory is Ownable {
    // mapping of all dkg addresses
    mapping(bytes32 => address) public dkgAddresses;

    // mapping of authorized node addresses
    mapping(address => bool) public authorizedNodes;

    event NewDKGCreated(bytes32 id, address dkg);

    function startNewDkg() public onlyOwner returns (bytes32, address) {
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
