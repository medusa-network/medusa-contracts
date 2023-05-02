# Medusa Smart Contracts
Core smart contracts powering the Medusa Network. Includes inheritable contracts for building applications that integrate with Medusa.

## Contracts

```ml
src
├── ArbSys - "System calls for Arbitrum"
├── BN254EncryptionOracle - "An implementation of EncryptionOracle that supports BN254"
├── Bn128 - "A library for operations over BN128 (a.k.a. BN254)"
├── DKG - "Implementation of a distributed key generation mediated by a smart contract"
├── DKGFactory - "Factory contract for deploying multiple DKG instances"
├── EncryptionOracle - "Abstract contract where Medusa nodes receive and respond to reencryption requests"
├── MedusaClient - "Contract for Medusa applications to inherit and implement"
├── OnlyFiles - "An example of a MedusaClient that implements 'pay-to-unlock' / 'fair exchange'"
├── OracleFactory - "Factory contract for deploying multiple EncryptionOracle instances"
├── Playground - "A contract used for tests in the core Medusa nodes codebase"
└── RoleACL - "A contract used for tests in the core Medusa nodes codebase"
```

## Safety
This is experimental software and is provided on an "as is" and "as available" basis.

## Installation
To install with [**Foundry**](https://github.com/gakonst/foundry):

```sh
forge install medusa-network/medusa-contracts
```

With Foundry, your imports would look like:
```solidity
// Assuming this line is in remappings.txt:
// medusa-contracts/=lib/medusa-contracts/src

import "medusa-contracts/MedusaClient.sol";

contract MyDapp is MedusaClient {
    ...        
}

```

To install with [**Hardhat**](https://github.com/nomiclabs/hardhat) or [**Truffle**](https://github.com/trufflesuite/truffle):

```sh
npm install @medusa-network/medusa-contracts
```

With Hardhat, your imports would look like:

```solidity

import "@medusa-network/medusa-contracts/src/MedusaClient.sol";

contract MyDapp is MedusaClient {
    ...        
}
```

## Developing

Be sure you've [Foundry](https://github.com/foundry-rs/foundry) installed on your computer. Foundry depends on Rust, so it's needed too.

After you've installed Foundry you'll be able to run `forge` commands. Follow these steps to run tests:

```sh
forge install
forge build
forge test
```
