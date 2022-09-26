// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EncryptionOracle} from "./EncryptionOracle.sol";
import {Bn128} from "./Bn128.sol";

contract OracleFactory is Ownable {
    EncryptionOracle oracle;

    event NewOracleCreated(address _oracle);

    function startNewOracle(Bn128.G1Point memory _distKey) public onlyOwner returns (address) {
        // For demo useless restriction more annoying than anything
        // TODO require(isOracleNull() || isOracleDone(), "oracle not in good stage");
        oracle = new EncryptionOracle(_distKey);
        emit NewOracleCreated(address(oracle));
        return address(oracle);
    }

    function isOracleNull() internal view returns (bool) {
        return address(oracle) == address(0);
    }
}
