// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Bn128} from "./Bn128.sol";
import {DKGFactory} from "./DKGFactory.sol";

interface IThresholdNetwork {
    function distributedKey() external view returns (Bn128.G1Point memory);
}

error InvalidPhase();
error ParticipantLimit();
error AlreadyRegistered();
error NotAuthorized();
error NotRegistered();
error InvalidSharesCount();
error InvalidCommitmentsCount();
error InvalidCommitment(uint256 index);

contract DKG is Ownable, IThresholdNetwork {
    // The maximum number of participants
    uint16 public constant MAX_PARTICIPANTS = 1000;
    // how many rounds/blocks compose one DKG phase
    uint8 public constant BLOCKS_PER_PHASE = 10;

    enum PHASE {
        INIT,
        REGISTRATION,
        DEAL
    }

    uint256 public initTime;
    uint256 public registrationTime;
    uint256 public dealTime;
    uint256 public complaintTime;

    function isInRegistrationPhase() public view returns (bool) {
        return block.number >= initTime && block.number < registrationTime;
    }

    function isInDealPhase() public view returns (bool) {
        return block.number >= registrationTime && block.number < dealTime;
    }

    function isInComplaintPhase() public view returns (bool) {
        return block.number >= dealTime && block.number < complaintTime;
    }

    function isDone() public view returns (bool) {
        return block.number >= complaintTime;
    }

    // list of participant index -> hash of the deals
    mapping(uint32 => uint256) private dealHashes;
    // list participant address -> index in the DKG
    mapping(address => uint32) private addressIndex;
    // list of index of the nodes currently accepted.
    uint32[] private nodeIndex;
    // number of users registered, serves to designate the index
    uint32 private nbRegistered = 0;
    // public key aggregated in "real time", each time a new deal comes in or a
    // new valid complaint comes in
    Bn128.G1Point internal distKey = Bn128.g1Zero();

    // Parent Factory
    DKGFactory private factory;

    // event emitted when the DKG is ready to start

    event NewParticipant(address from, uint32 index, uint256 tmpKey);
    // TODO change when this is fixed https://github.com/gakonst/ethers-rs/issues/1220
    event DealBundleSubmitted(
        uint256 dealerIdx, Bn128.G1Point random, uint32[] indices, uint256[] shares, Bn128.G1Point[] commitment
    );
    event ValidComplaint(address from, uint32 evicted);

    constructor(DKGFactory _factory) Ownable() {
        initTime = block.number;
        registrationTime = initTime + BLOCKS_PER_PHASE;
        dealTime = registrationTime + BLOCKS_PER_PHASE;
        complaintTime = dealTime + BLOCKS_PER_PHASE;
        factory = _factory;
    }

    // Registers a participants and assigns him an index in the group
    // TODO make it payable in a super contract
    function registerParticipant(uint256 _tmpKey) public {
        if (!isInRegistrationPhase()) {
            revert InvalidPhase();
        }
        if (nbRegistered >= MAX_PARTICIPANTS) {
            revert ParticipantLimit();
        }
        // TODO check for BN128 subgroup instead
        //require(_tmpKey != 0, "Invalid key");
        // TODO check for uniqueness of the key as well
        if (addressIndex[msg.sender] != 0) {
            revert AlreadyRegistered();
        }
        if (!factory.isAuthorizedNode(msg.sender)) {
            revert NotAuthorized();
        }
        // index will start at 1
        nbRegistered++;
        uint32 index = nbRegistered;
        nodeIndex.push(index);
        addressIndex[msg.sender] = index;
        emit NewParticipant(msg.sender, index, _tmpKey);
    }

    function numberParticipants() public view returns (uint256) {
        return nbRegistered;
    }

    struct DealBundle {
        Bn128.G1Point random;
        uint32[] indices;
        uint256[] encryptedShares;
        Bn128.G1Point[] commitment;
    }

    function emitDealBundle(uint32 _index, DealBundle memory _bundle) private {
        emit DealBundleSubmitted(_index, _bundle.random, _bundle.indices, _bundle.encryptedShares, _bundle.commitment);
    }

    // TODO
    //function dealHash(DealBundle memory _bundle) pure returns (uint256) {
    //uint comm_len = 2 * 32 * _bundle.commitment.length;
    //share_len = _bundle.shares.length * (2 + 32*2 + 32);
    //uint32 len32 = (comm_len + share_len) / 4;
    //uint32[] memory hash = new uint32[](len32);
    //for
    //}

    function submitDealBundle(DealBundle memory _bundle) public isRegistered {
        uint32 index = indexOfSender();
        if (!isInDealPhase()) {
            revert InvalidPhase();
        }
        if (index == 0) {
            revert NotRegistered();
        }
        // 1. Check he submitted enough encrypted shares
        // We expect the dealer to submit his own too.
        // TODO : do we have too ?
        if (_bundle.encryptedShares.length != numberParticipants()) {
            revert InvalidSharesCount();
        }
        // 2. Check he submitted enough committed coefficients
        // TODO Check actual bn128 check on each of them
        uint256 len = threshold();
        if (_bundle.commitment.length != len) {
            revert InvalidCommitmentsCount();
        }
        // 3. Check that commitments are all on the bn128 curve by decompressing
        // them
        // TODO hash
        //uint256[] memory compressed = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            // TODO save the addition of those if successful later
            //comms[i] = Bn128.g1Decompress(bytes32(_commitment[i]));
            if (!Bn128.isG1PointOnCurve(_bundle.commitment[i])) {
                revert InvalidCommitment(i);
            }
            //compressed[i] = uint256(Bn128.g1Compress(_commitment[i]));
        }
        // 3. Compute and store the hash
        //bytes32 comm = keccak256(abi.encodePacked(_encrypted_shares,compressed));
        // TODO check it is not done before
        //deal_hashes[indexOfSender()] = uint256(comm);
        // 4. add the key to the aggregated key
        distKey = Bn128.g1Add(distKey, _bundle.commitment[0]);
        // 5. emit event
        //emit DealBundleSubmitted(index, _bundle);
        emitDealBundle(index, _bundle);
    }

    function submitComplaintBundle() public {
        // TODO
        emit ValidComplaint(msg.sender, 0);
    }

    // Returns the list of indexes of QUALIFIED participants at the end of the DKG.
    function participantIndexes() public view returns (uint32[] memory) {
        if (!isDone()) {
            revert InvalidPhase();
        }
        return nodeIndex;
    }

    function distributedKey() public view override returns (Bn128.G1Point memory) {
        // Currently only demo so more annoying than anything else
        // TODO
        // require(isDone(),"don't fetch public key before DKG is done");
        //return uint256(Bn128.g1Compress(distKey));
        return distKey;
    }

    function threshold() public view returns (uint256) {
        return numberParticipants() / 2 + 1;
    }

    modifier isRegistered() {
        if (addressIndex[msg.sender] == 0) {
            revert NotRegistered();
        }
        _;
    }

    function indexOfSender() public view returns (uint32) {
        return addressIndex[msg.sender];
    }
}
