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
    enum Status {
        CREATED,
        REGISTRATION,
        DKG_PROGRESS
    }

    // list of participants, indexed by their eth key and value is their temporary DKG key
    mapping (address => uint256) private nodes;
    mapping (address => uint256) private deal_hashes;
    // number of users registered
    uint nbRegistered = 0;
    // current status of the DKG - Note that once the DKG has started, the phases are evolving 
    // by themselves just with the block number increasing.
    Status private status = Status.CREATED;
    // the block number at which the dkg started
    uint private deal_block = 0;

    constructor() {

    }

    // event emitted when the DKG is ready to start
    event DKGStart();

    
    // TODO make it payable in a super contract
    function registerParticipant(uint256 _tmpKey) public {
        require(status == Status.REGISTRATION, "You can not register yet!");
        require(nbRegistered < MAX_PARTICIPANTS, 
            "too many participants registered");
        // TODO check for BN128 subgroup instead
        require(_tmpKey != 0, "Invalid key");
        // TODO check for uniqueness of the key
        require(nodes[msg.sender] == 0, "Already registered participant");
        nbRegistered++;
        nodes[msg.sender] = _tmpKey;
    }

    function numberParticipants() public view returns (uint256) {
        return nbRegistered;
    }

    function startRegistration() public onlyOwner {
        require(status == Status.CREATED,"Invalid state transition to REGISTRATION");
        status = Status.REGISTRATION;
    }
    // startDKG sets the status such that participants can now submit their deals 
    // onchain
    function startDKG() public onlyOwner {
        require(status == Status.REGISTRATION,"Invalid state transition to DKG_DEALS");
        // TODO check for a threshold of nodes present
        status = Status.DKG_PROGRESS;
        deal_block = block.number;
    }

    function submitDeal(uint256[2][] memory _encrypted_shares,uint256[] memory _commitment) public isRegistered {
        require(status == Status.DKG_PROGRESS,"DKG has not started yet");
        require(block.number > deal_block,"Something is off with the beginning of the DKG");
        require(block.number < next_phase(deal_block),"Too late to submit deal");

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

    function next_phase(uint start) public pure returns (uint) {
        return start + uint(BLOCKS_PER_PHASE);
    }

    function threshold() public view returns (uint) {
        return numberParticipants() / 2 + 1;
    }

    modifier isRegistered() {
        require(nodes[msg.sender] != 0, "You are not registered for the DKG");
        _;
    }
}
