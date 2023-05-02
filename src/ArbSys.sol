// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

uint256 constant ARBITRUM_ONE = 42161;
uint256 constant ARBITRUM_GOERLI = 421613;

interface ArbSys {
    function arbBlockNumber() external view returns (uint256);
}
