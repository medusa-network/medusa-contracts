// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EncryptionOracle.sol";

contract OracleFactory is Ownable {

    EncryptionOracle oracle; 

    event NewOracleCreated(address _oracle);
    
    function startNewOracle() public onlyOwner returns (address) {
        // For demo useless restriction more annoying than anything
        // TODO require(isOracleNull() || isOracleDone(), "oracle not in good stage");
        oracle = new EncryptionOracle();
        emit NewOracleCreated(address(oracle));
        return address(oracle);
    }

    function isOracleNull() internal view returns (bool) {
        return address(oracle) == address(0);
    }
    function isOracleDone() internal view returns (bool) {
        return oracle.isDone();
    }
}

