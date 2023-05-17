// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

// TODO: Is it bad practice to use Ownable from OZ and Solady?
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC1967Factory} from "solady/utils/ERC1967Factory.sol";

contract OracleFactory is ERC1967Factory, Ownable {
    event NewOracleDeployed(address oracle);

    function _deploy(
        address implementation,
        address admin,
        bytes32 salt,
        bool useSalt,
        bytes calldata data
    ) internal override onlyOwner returns (address) {
        address oracle =
            ERC1967Factory._deploy(implementation, admin, salt, useSalt, data);

        emit NewOracleDeployed(oracle);
        return oracle;
    }
}
