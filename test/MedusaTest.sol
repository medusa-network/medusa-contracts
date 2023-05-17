// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

abstract contract MedusaTest is Test {
    address internal owner;
    address internal notOwner;
    address internal relayer;

    constructor() {
        setEnv();

        owner = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        (, uint256 nonOwnerKey) = makeAddrAndKey("notOwner");
        notOwner = vm.rememberKey(nonOwnerKey);

        relayer = makeAddr("relayer");
    }

    function setEnv() private {
        /// First EOA in anvil
        vm.setEnv(
            "PRIVATE_KEY",
            "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
        );

        vm.setEnv(
            "NODE_1_ADDRESS", "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
        );
        vm.setEnv(
            "NODE_2_ADDRESS", "0x70997970c51812dc3a010c7d01b50e0d17dc79c8"
        );
        vm.setEnv(
            "NODE_3_ADDRESS", "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc"
        );
    }
}
