// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {OracleFactory, Suite} from "../src/OracleFactory.sol";
import {G1Point} from "../src/Bn128.sol";
import "forge-std/console2.sol";

contract OracleFactoryDeploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        uint256 keyX = vm.envUint("DISTRIBUTED_KEY_X");
        uint256 keyY = vm.envUint("DISTRIBUTED_KEY_Y");

        G1Point memory key = G1Point(keyX, keyY);

        OracleFactory factory = new OracleFactory();
        address oracleAddress = factory.deployNewOracle(key, Suite.BN254_KEYG1_HGAMAL);
        vm.stopBroadcast();

        console2.log("Oracle Factory:", address(factory));
        console2.log("Oracle Address:", oracleAddress);
    }
}
