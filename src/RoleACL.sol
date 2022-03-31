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

    event NewOracleResult(uint256 _id, uint256 r, uint256 cipher, uint256 publickey);

    function isAuthorized(uint256, uint256 _publickey, uint256[] memory) external view returns (bool) {
        //require(extra.length == 1);
        //bytes32 role = bytes32(extra[0]);
        // TODO can actually take role from extra but need to be careful with
        // assumptions
        // Iterate over all members of the role, get their associated public key
        // and check if it is the same. if it is, our public key is in the
        // reader set. Given this function can be ran locally it matters little 
        uint256 count = getRoleMemberCount(READER_ROLE);
        for (uint256 i = 0; i < count; i ++) {
            address addr = getRoleMember(READER_ROLE,i);
            if (addressToKey[addr] == _publickey) { 
                return true;
            }
        }
        return false;
    }
    function oracleResult(uint256 id, uint256 r, uint256 cipher, uint256 publickey) external {
        emit NewOracleResult(id,r,cipher,publickey);
    }

    // TODO payable
    function submitCiphertext(bytes32 _role, uint256 _r, uint256 _cipher) public onlyRole(WRITER_ROLE) {
        uint256[] memory extra = new uint256[](1);
        extra[1] = uint256(_role);
        oracle.submitCiphertext(_r,_cipher, extra);
    }

    function askForDecryption(uint256 id) external {
        // check if it is registered correctly
        require(addressToKey[msg.sender] != 0, "no registered public key");
        //  check if it has the right permission
        require(hasRole(READER_ROLE, msg.sender), "Caller is not a reader");
        uint256 pubkey = addressToKey[msg.sender];
        oracle.requestReencryption(id, pubkey);
    }

    function grantRole(bytes32 _role, address) public view override(AccessControl,IAccessControl) onlyRole(getRoleAdmin(_role)) {
        // TODO check if there are other public functions to restrict
        require(false, "This can not be called - call grantRoleKey");
    }

    function grantRoleKey(bytes32 role, address account, uint256 pubkey) public onlyRole(getRoleAdmin(role)) {
        require(pubkey != 0,"public key can't be 0");
        super.grantRole(role,account); 
        addressToKey[account] = pubkey;
    }

    function revokeRole(bytes32 _role, address _account) public virtual override(AccessControl,IAccessControl) onlyRole(getRoleAdmin(_role)) {
        super.revokeRole(_role, _account); 
        delete(addressToKey[_account]);
    }
}

