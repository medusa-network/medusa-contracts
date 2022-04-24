// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Bn128.sol";

contract DKGManager is Ownable {
    // The maximum number of participants
    uint16 constant public MAX_PARTICIPANTS = 1000;
    // how many rounds/blocks compose one DKG phase
    uint8 constant public BLOCKS_PER_PHASE = 10;
    enum PHASE {
        INIT,
        REGISTRATION,
        DEAL
    }

    uint256 public init_time;
    uint256 public registration_time;
    uint256 public deal_time;
    uint256 public complaint_time;

    function isInRegistrationPhase() public view returns (bool) {
        return block.number > init_time && block.number < registration_time;
    }
    function isInDealPhase() public view returns (bool) {
        return block.number >= registration_time && block.number < deal_time;
    }
    function isInComplaintPhase() public view returns (bool) {
        return block.number >= deal_time && block.number < complaint_time;
    }
    function isDone() public view returns (bool) {
        return block.number >= complaint_time;
    }

    // list of participant index -> hash of the deals
    mapping (uint32 => uint256) private deal_hashes;
    // list participant address -> index in the DKG
    mapping (address => uint32) private address_index;
    // list of index of the nodes currently accepted.
    uint32[] private node_index;
    // number of users registered, serves to designate the index
    uint32 nbRegistered = 0;
    // public key aggregated in "real time", each time a new deal comes in or a
    // new valid complaint comes in
    Bn128.G1Point internal dist_key = Bn128.g1Zero();
    // event emitted when the DKG is ready to start
    event NewParticipant(address from, uint32 index, uint256 tmpKey);
    event DealBundleSubmitted(uint256 dealer_idx, uint256[3][] encrypted_shares,uint256[] commitment);
    event ValidComplaint(address from, uint32 evicted);
    
    constructor()  Ownable() {
        init_time = block.number; 
        registration_time = init_time + BLOCKS_PER_PHASE;
        deal_time = registration_time + BLOCKS_PER_PHASE;
        complaint_time = deal_time + BLOCKS_PER_PHASE;
    }

    // Registers a participants and assigns him an index in the group
    // TODO make it payable in a super contract
    function registerParticipant(uint256 _tmpKey) public  {
        require(isInRegistrationPhase(), "You can not register yet!");
        require(nbRegistered < MAX_PARTICIPANTS, 
            "too many participants registered");
        // TODO check for BN128 subgroup instead
        require(_tmpKey != 0, "Invalid key");
        // TODO check for uniqueness of the key as well
        require(address_index[msg.sender] == 0, "Already registered participant");
        // index will start at 1
        nbRegistered++;
        uint32 index = nbRegistered;
        node_index.push(index);
        address_index[msg.sender] = index;
        emit NewParticipant(msg.sender, index, _tmpKey);
    }

    function numberParticipants() public view returns (uint256) {
        return nbRegistered;
    }

    function submitDealBundle(uint256[3][] memory _encrypted_shares,uint256[] memory _commitment) public isRegistered {
        require(isInDealPhase(),"DKG is not in the deal phase");
        // 1. Check he submitted enough encrypted shares
        // We expect the dealer to submit his own too.
        // TODO : do we have too ?
        require(_encrypted_shares.length == numberParticipants(), "Different number of encrypted shares");
        // 2. Check he submitted enough committed coefficients
        // TODO Check actual bn128 check on each of them
        require(_commitment.length == threshold(), "Invalid number of commitments");
        // 3. Check that commitments are all on the bn128 curve by decompressing
        // them
        Bn128.G1Point[] memory comms = new Bn128.G1Point[](_commitment.length);
        for (uint i = 0; i < _commitment.length; i++) {
            // TODO save them in the contract
            comms[i] = Bn128.g1Decompress(bytes32(_commitment[i]));
        }
        // 3. Compute and store the hash
        bytes32 comm = sha256(abi.encodePacked(_encrypted_shares,_commitment));
        deal_hashes[indexOfSender()] = uint256(comm);
        // 4. add the key to the aggregated key 
        dist_key = Bn128.g1Add(dist_key, comms[0]);
        // 5. emit event 
        emit DealBundleSubmitted(indexOfSender(), _encrypted_shares, _commitment);
    }

    function submitComplaintBundle() public {
        // TODO
        emit ValidComplaint(msg.sender, 0);
    }

    // Returns the list of indexes of QUALIFIED participants at the end of the DKG.
    function participantIndexes() public view returns (uint32[] memory) {
        require(isDone(),"indexes are of no interest if the DKG is not finished");
        return node_index;
    }

    function distributedKey() public view returns (uint256) {
        // Currently only demo so more annoying than anything else 
        // TODO
        // require(isDone(),"don't fetch public key before DKG is done");
        return uint256(Bn128.g1Compress(dist_key));
    }

    function threshold() public view returns (uint) {
        return numberParticipants() / 2 + 1;
    }

    modifier isRegistered() {
        require(address_index[msg.sender] != 0, "You are not registered for the DKG");
        _;
    }

    function indexOfSender() public view returns (uint32) {
        return address_index[msg.sender];
    }

}
