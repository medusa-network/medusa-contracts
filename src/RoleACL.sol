// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import { IEncryptionOracle as IO, IEncryptionClient } from "./EncryptionOracle.sol";
import "./Bn128.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


// A simple role based ACL that broadcast a ciphertext when requested to all
// current roles. It doesn't support yet broadcasting only to new role members
// in the future etc.
contract RoleACL is AccessControlEnumerable, IEncryptionClient {

    bytes32 public constant READER_ROLE = keccak256("READER_ROLE");
    bytes32 public constant WRITER_ROLE = keccak256("WRITER_ROLE");

    IO private oracle;
    mapping(address => Bn128.G1Point) private addressToKey;


    constructor(address _oracleAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // we automatically set the admin as a writer as well for more
        // convenience
        _setupRole(WRITER_ROLE, msg.sender);
        oracle = IO(_oracleAddress);
    }

    // TODO Fix with a proper struct once 
    // https://github.com/gakonst/ethers-rs/issues/1219 is fixed
    // request id of the reeencryption
    event NewOracleResult(uint256 _id, uint256 rx, uint256 ry, uint256 cipher);

    //function isAuthorized(uint256, uint256 _publickey, uint256[] memory) external view returns (bool) {
        ////require(extra.length == 1);
        ////bytes32 role = bytes32(extra[0]);
        //// TODO can actually take role from extra but need to be careful with
        //// assumptions
        //// Iterate over all members of the role, get their associated public key
        //// and check if it is the same. if it is, our public key is in the
        //// reader set. Given this function can be ran locally it matters little 
        //uint256 count = getRoleMemberCount(READER_ROLE);
        //for (uint256 i = 0; i < count; i ++) {
            //address addr = getRoleMember(READER_ROLE,i);
            //if (addressToKey[addr] == _publickey) { 
                //return true;
            //}
        //}
        //return false;
    //}

    function oracleResult(uint256 _request_id, IO.Ciphertext memory _cipher) external {
        require(msg.sender == address(oracle), "only oracle can submit results");
        // TODO : some checks ? do we handle pending requests here etc ?
        emit NewOracleResult(_request_id,_cipher.random.x,_cipher.random.y,_cipher.cipher);
    }

    // TODO add different roles, payable etc
    function submitCiphertext(IO.Ciphertext memory _cipher) public onlyRole(WRITER_ROLE) returns (uint256) {
        return oracle.submitCiphertext(_cipher);
    }

    function askForDecryption(uint256 _id) external {
        Bn128.G1Point memory pubkey = addressToKey[msg.sender];
        //  check if it has the right permission
        require(hasRole(READER_ROLE, msg.sender), "Caller is not a reader");
        oracle.requestReencryption(_id, pubkey);
    }

    function grantRole(bytes32 _role, address) public view override onlyRole(getRoleAdmin(_role)) {
        // TODO check if there are other public functions to restrict
        require(false, "This can not be called - call grantRoleKey");
    }

    function grantRoleKey(bytes32 _role, address _account, Bn128.G1Point memory _pubkey) public onlyRole(getRoleAdmin(_role)) {
        require(_pubkey.x != 0,"public key can't be 0");
        require(_pubkey.y != 0,"public key can't be 0");
        super.grantRole(_role,_account); 
        addressToKey[_account] = _pubkey;
    }

    function revokeRole(bytes32 _role, address _account) public virtual override onlyRole(getRoleAdmin(_role)) {
        super.revokeRole(_role, _account); 
        delete(addressToKey[_account]);
    }

    function getKeyForAddress(address _account) public view returns (Bn128.G1Point memory) {
        return addressToKey[_account];
    }

    function getOracleAddress() public view returns (address) {
        return address(oracle);
    }
}

