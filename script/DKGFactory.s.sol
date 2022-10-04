// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/DKGFactory.sol";
import "forge-std/console2.sol";

contract DKGFactoryDeploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DKGFactory factory = new DKGFactory();
        (bytes32 dkgId, address dkgAddress) = factory.deployNewDKG();

        vm.stopBroadcast();
        console2.log("DKG Factory:", address(factory));
        console2.log("DKG ID:", uint256(dkgId));
        console2.log("DKG Address:", dkgAddress);
    }
}
