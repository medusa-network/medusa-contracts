// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "./EncryptionOracle.sol";
import "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";


// A simple role based ACL that broadcast a ciphertext when requested to all
// current roles. It doesn't support yet broadcasting only to new role members
// in the future etc.
contract RoleACL is AccessControlEnumerable {
    bytes32 public constant READER_ROLE = keccak256("READER_ROLE");
    bytes32 public constant WRITER_ROLE = keccak256("WRITER_ROLE");

    IEncryptionOracle private oracle;
    mapping(address => uint256) private addressToKey;


    constructor(address _oracleAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        oracle = IEncryptionOracle(_oracleAddress);
    }

    // TODO payable
    function submitCiphertextForRole(uint256 _r, uint256 _cipher) public onlyRole(WRITER_ROLE) {
        uint256 count = getRoleMemberCount(READER_ROLE); 
        for (uint256 i = 0; i < count; i++) {
            address recipient = getRoleMember(READER_ROLE,i);
            uint256 pubkey = addressToKey[recipient];
            oracle.requestReencryption(_r,_cipher,pubkey);
        }
    }

    function grantRole(bytes32 _role, address) public view override(AccessControl,IAccessControl) onlyRole(getRoleAdmin(_role)) {
        require(false, "This can not be called - call grantRoleKey");
    }

    function grantRoleKey(bytes32 role, address account, uint256 pubkey) public onlyRole(getRoleAdmin(role)) {
        super.grantRole(role,account); 
        addressToKey[account] = pubkey;
    }
}

