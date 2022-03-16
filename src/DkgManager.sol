// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract DKGManager is Ownable {
    // The maximum number of participants
    uint16 constant public MAX_PARTICIPANTS = 1000;
    // how many rounds/blocks compose one DKG phase
    uint8 constant public BLOCKS_PER_PHASE = 10;
    struct Node {
        address ethKey;
        uint256 bn254Key;
    }
    enum PHASE {
        INIT,
        REGISTRATION,
        DEAL
    }

    uint256 public init_time;
    uint256 public registration_time;
    uint256 public deal_time;

    function isInRegistrationPhase() public view returns (bool) {
        return block.number > init_time && block.number < registration_time;
    }
    function isInDealPhase() public view returns (bool) {
        return block.number > registration_time && block.number < deal_time;
    }

    // list of participants, indexed by their eth key and value is their temporary DKG key
    mapping (address => uint256) private nodes;
    mapping (address => uint256) private deal_hashes;
    // number of users registered
    uint nbRegistered = 0;
    // event emitted when the DKG is ready to start
    event NewParticipant(address from, uint256 tmpKey);


    constructor()  Ownable() {
        init_time = block.number; 
        registration_time = init_time + BLOCKS_PER_PHASE;
        deal_time = registration_time + BLOCKS_PER_PHASE;
    }
    // TODO make it payable in a super contract
    function registerParticipant(uint256 _tmpKey) public {
        require(isInRegistrationPhase(), "You can not register yet!");
        require(nbRegistered < MAX_PARTICIPANTS, 
            "too many participants registered");
        // TODO check for BN128 subgroup instead
        require(_tmpKey != 0, "Invalid key");
        // TODO check for uniqueness of the key as well
        require(nodes[msg.sender] == 0, "Already registered participant");
        nbRegistered++;
        nodes[msg.sender] = _tmpKey;
        emit NewParticipant(msg.sender,_tmpKey);
    }

    function numberParticipants() public view returns (uint256) {
        return nbRegistered;
    }

    function submitDeal(uint256[2][] memory _encrypted_shares,uint256[] memory _commitment) public isRegistered {
        require(isInDealPhase(),"DKG has not started yet");

        // 1. Check he submitted enough encrypted shares
        // We expect the dealer to submit his own too.
        // TODO : do we have too ?
        require(_encrypted_shares.length == numberParticipants(), "Different number of encrypted shares");
        // 2. Check he submitted enough committed coefficients
        // TODO Check actual bn128 check on each of them
        require(_commitment.length == threshold(), "Invalid number of commitments");
        // 3. Compute and store the hash
        bytes32 comm = sha256(abi.encodePacked(_encrypted_shares,_commitment));
        deal_hashes[msg.sender] = uint256(comm);
    }

    function threshold() public view returns (uint) {
        return numberParticipants() / 2 + 1;
    }

    modifier isRegistered() {
        require(nodes[msg.sender] != 0, "You are not registered for the DKG");
        _;
    }
}
