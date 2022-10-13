// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Bn128, G1Point} from "./Bn128.sol";
import {DKGFactory} from "./DKGFactory.sol";
import {ArbSys, ARBITRUM_ONE, ARBITRUM_GOERLI} from "./ArbSys.sol";

error InvalidPhase();
error ParticipantLimit();
error AlreadyRegistered();
error NotAuthorized();
error NotRegistered();
error InvalidSharesCount();
error InvalidCommitmentsCount();
error InvalidCommitment(uint256 index);

/// @title ThresholdNetwork
/// @author Cryptonet
/// @notice This contract represents a threshold network.
/// @dev All threshold networks have a distributed key;
/// the DKG contract facilitates the generation of a key, whereas Oracle contracts are given a key
abstract contract ThresholdNetwork {
    G1Point internal distKey;

    constructor(G1Point memory _distKey) {
        distKey = _distKey;
    }

    function distributedKey() external view virtual returns (G1Point memory) {
        return distKey;
    }
}

/// @notice A bundle of deals submitted by each participant.
struct DealBundle {
    G1Point random;
    uint32[] indices;
    uint256[] encryptedShares;
    G1Point[] commitment;
}

interface IDKG {
    enum Phase {
        REGISTRATION,
        DEAL,
        COMPLAINT,
        DONE
    }

    /// @notice Emitted when a new participant registers during the registration phase.
    /// @param from The address of the participant.
    /// @param index The index of the participant.
    /// @param tmpKey The temporary key of the participant.
    event NewParticipant(address from, uint32 index, uint256 tmpKey);

    /// @notice Emitted when a deal is submitted during the deal phase.
    /// @param dealerIdx The index of the dealer submitting the deal.
    /// @param bundle The deal bundle submitted by the dealer.
    event DealBundleSubmitted(uint256 dealerIdx, DealBundle bundle);

    /// @notice Emitted when a valid complaint is submitted during the complaint phase.
    /// @param from The address of the participant who submitted the complaint.
    /// @param evicted The index of the dealer who is evicted from the network.
    event ValidComplaint(address from, uint32 evicted);
}

/// @title Distributed Key Generation
/// @notice This contract implements the trusted mediator for the Deji DKG protocol.
/// @dev The DKG protocol is a three-phase protocol. In the first phase, authorized nodes register as partcipants
/// In the second phase, participants submit their deals.
/// In the third phase, participants submit complaints for invalid deals.
/// The contract verifies the commitments and computes the public key based on valid commitments.
/// @author Cryptonet
contract DKG is ThresholdNetwork, IDKG {
    using Bn128 for G1Point;

    /// @notice The maximum number of participants
    uint16 public constant MAX_PARTICIPANTS = 1000;

    /// @notice Each phase lasts 10 blocks
    uint8 public constant BLOCKS_PER_PHASE = 10;

    /// @notice The block number at which this contract is deployed
    uint256 public initTime;

    /// @notice The ending block number for each phase
    uint256 public registrationTime;
    uint256 public dealTime;
    uint256 public complaintTime;

    /// @notice Maps participant index to hash of their deal
    mapping(uint32 => uint256) private dealHashes;

    /// @notice Maps participant address to their index in the DKG
    mapping(address => uint32) private addressIndex;

    /// @notice List of index of the nodes currently registered
    uint32[] private nodeIndex;

    /// @notice Number of nodes registered
    /// @dev serves to designate the index
    uint32 private nbRegistered = 0;

    /// @notice The parent factory which deployed this contract
    DKGFactory private factory;

    modifier onlyRegistered() {
        if (addressIndex[msg.sender] == 0) {
            revert NotRegistered();
        }
        _;
    }

    modifier onlyAuthorized() {
        if (!factory.isAuthorizedNode(msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlyPhase(Phase phase) {
        if (phase == Phase.REGISTRATION) {
            if (!isInRegistrationPhase()) {
                revert InvalidPhase();
            }
        } else if (phase == Phase.DEAL) {
            if (!isInDealPhase()) {
                revert InvalidPhase();
            }
        } else if (phase == Phase.COMPLAINT) {
            if (!isInComplaintPhase()) {
                revert InvalidPhase();
            }
        } else if (phase == Phase.DONE) {
            if (!isDone()) {
                revert InvalidPhase();
            }
        }
        _;
    }

    /// @notice Create a new DKG with an empty public key
    /// @dev The public key is aggregated in "real time" for each new deal or new valid complaint transaction
    constructor(DKGFactory _factory) ThresholdNetwork(Bn128.g1Zero()) {
        initTime = blockNumber();
        registrationTime = initTime + BLOCKS_PER_PHASE;
        dealTime = registrationTime + BLOCKS_PER_PHASE;
        complaintTime = dealTime + BLOCKS_PER_PHASE;
        factory = _factory;
    }

    function isInRegistrationPhase() public view returns (bool) {
        uint256 blockNum = blockNumber();
        return blockNum >= initTime && blockNum < registrationTime;
    }

    function isInDealPhase() public view returns (bool) {
        uint256 blockNum = blockNumber();
        return blockNum >= registrationTime && blockNum < dealTime;
    }

    function isInComplaintPhase() public view returns (bool) {
        uint256 blockNum = blockNumber();
        return blockNum >= dealTime && blockNum < complaintTime;
    }

    function isDone() public view returns (bool) {
        uint256 blockNum = blockNumber();
        return blockNum >= complaintTime;
    }

    /// @notice Registers a participant and assigns it an index in the group
    /// @dev Only authorized nodes from the factory can register
    /// @param _tmpKey The temporary key of the participant
    /// @custom:todo make it payable in a super contract
    function registerParticipant(uint256 _tmpKey) external onlyAuthorized onlyPhase(Phase.REGISTRATION) {
        if (nbRegistered >= MAX_PARTICIPANTS) {
            revert ParticipantLimit();
        }
        // TODO check for BN128 subgroup instead
        //require(_tmpKey != 0, "Invalid key");
        // TODO check for uniqueness of the key as well
        if (addressIndex[msg.sender] != 0) {
            revert AlreadyRegistered();
        }
        // index will start at 1
        nbRegistered++;
        uint32 index = nbRegistered;
        nodeIndex.push(index);
        addressIndex[msg.sender] = index;
        emit NewParticipant(msg.sender, index, _tmpKey);
    }

    // TODO
    //function dealHash(DealBundle memory _bundle) pure returns (uint256) {
    //uint comm_len = 2 * 32 * _bundle.commitment.length;
    //share_len = _bundle.shares.length * (2 + 32*2 + 32);
    //uint32 len32 = (comm_len + share_len) / 4;
    //uint32[] memory hash = new uint32[](len32);
    //for
    //}

    /// @notice Submit a deal bundle
    /// @dev Can only be called by registered nodes while in the deal phase
    /// @param _bundle The deal bundle; a struct containing the random point, the indices of the nodes to which the shares are encrypted,
    /// the encrypted shares and the commitments to the shares
    function submitDealBundle(DealBundle calldata _bundle) external onlyRegistered onlyPhase(Phase.DEAL) {
        uint32 index = indexOfSender();
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
            if (!_bundle.commitment[i].isG1PointOnCurve()) {
                revert InvalidCommitment(i);
            }
            //compressed[i] = uint256(Bn128.g1Compress(_commitment[i]));
        }
        // 3. Compute and store the hash
        //bytes32 comm = keccak256(abi.encodePacked(_encrypted_shares,compressed));
        // TODO check it is not done before
        //deal_hashes[indexOfSender()] = uint256(comm);
        // 4. add the key to the aggregated key
        distKey = distKey.g1Add(_bundle.commitment[0]);
        // 5. emit event
        //emit DealBundleSubmitted(index, _bundle);
        emitDealBundle(index, _bundle);
    }

    /// @notice Submit a complaint against a deal
    /// @dev The complaint is valid if the deal is not valid and the complainer
    /// has a share of the deal
    /* /// @param _index The index of the deal to complain against
    /// @param _encryptedShare The encrypted share of the complainer
    /// @param _commitment The commitment of the complainer
    /// @param _deal The deal to complain against */
    /// @custom:todo Implement
    function submitComplaintBundle() external onlyRegistered onlyPhase(Phase.COMPLAINT) {
        // TODO
        emit ValidComplaint(msg.sender, 0);
    }

    function numberParticipants() public view returns (uint256) {
        return nbRegistered;
    }

    // Returns the list of indexes of QUALIFIED participants at the end of the DKG.
    function participantIndexes() public view onlyPhase(Phase.DONE) returns (uint32[] memory) {
        return nodeIndex;
    }

    function distributedKey() public view override onlyPhase(Phase.DONE) returns (G1Point memory) {
        //return uint256(Bn128.g1Compress(distKey));
        return distKey;
    }

    function threshold() public view returns (uint256) {
        return numberParticipants() / 2 + 1;
    }

    function indexOfSender() public view returns (uint32) {
        return addressIndex[msg.sender];
    }

    function emitDealBundle(uint32 _index, DealBundle memory _bundle) private {
        emit DealBundleSubmitted(_index, _bundle);
    }

    /// @notice returns the current block number of the chain of execution
    /// @dev Calling block.number on Arbitrum returns the L1 block number, which is not desired
    function blockNumber() private view returns (uint256) {
        if (block.chainid == ARBITRUM_ONE || block.chainid == ARBITRUM_GOERLI) {
            return ArbSys(address(100)).arbBlockNumber();
        } else {
            return block.number;
        }
    }
}
