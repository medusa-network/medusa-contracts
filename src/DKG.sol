// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Bn128, G1Point, DleqProof} from "./Bn128.sol";
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

enum ComplaintReturn {
    ValidComplaint,
    InvalidDealerIdx,
    InvalidHash,
    InvalidDleq,
    InvalidConsistentShare
}

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
    event NewParticipant(address from, uint32 index, G1Point tmpKey);

    /// @notice Emitted when a deal is submitted during the deal phase.
    /// @param dealerIdx The address of the dealer submitting the deal.
    /// @param bundle The deal bundle submitted by the dealer.
    event DealBundleSubmitted(uint32 dealerIdx, DealBundle bundle);

    /// @notice Emitted when a participant is evicted from the protocol. It can
    /// happen during any phases.
    /// @param from The address of the participant who got evicted
    /// @param index The index of the participant who is evicted from the network.
    event EvictedParticipant(address from, uint32 index);
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

    /// @notice The final label to use in the DLEQ transcript
    uint256 public constant COMPLAINT_LABEL = 1337;

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

    /// @notice Maps participant address to the temporary key used for this DKG
    mapping(address => G1Point) private pubkeys;

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
    function registerParticipant(G1Point memory _tmpKey) external onlyAuthorized onlyPhase(Phase.REGISTRATION) {
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
        addressIndex[msg.sender] = index;
        pubkeys[msg.sender] = _tmpKey;
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
        if (_bundle.encryptedShares.length != numberParticipants()) {
            revert InvalidSharesCount();
        }
        // 2. Check he submitted enough committed coefficients
        uint256 len = threshold();
        if (_bundle.commitment.length != len) {
            revert InvalidCommitmentsCount();
        }
        // 3. Check that commitments are all on the bn128 curve by decompressing
        // them
        for (uint256 i = 0; i < len; i++) {
            if (!_bundle.commitment[i].isG1PointOnCurve()) {
                revert InvalidCommitment(i);
            }
        }

        // 4. Compute and store the hash if not stored previously
        uint256 bundleHash = hashDealBundle(_bundle);
        if (dealHashes[index] != 0) {
            revert AlreadyRegistered();
        }
        dealHashes[index] = bundleHash;
        // 5. add the key to the aggregated key
        // Note this is not strictly required but is much easier to do it in contract
        // rather than having someone else upload the result onchain.
        // Note this distkey is _not yet_ valid - if this participant submitted
        // an invalid deal, it will get complained about and "rejected" later on.
        // His contribution to the public key will get removed. This is done here
        // in an "optimistic" way.
        distKey = distKey.g1Add(_bundle.commitment[0]);
        // 6. emit event so every other participant can pick it up
        emitDealBundle(index, _bundle);
    }

    /// @notice Submit a complaint against a deal
    /// @dev The complaint is valid if the deal is not valid and the complainer
    /// has a share of the deal. Note that if the complaint is invalid, it is
    /// the sender/complainer that is being evicted !
    /// @param dealer The address of the dealer to complain against
    /// @param badBundle the deal bundle which is claimed to be invalid
    /// @param sharedKey the key shared between the recipient and the dealer
    /// @custom:todo Implement
    function submitComplaintBundle(
        address dealer,
        DealBundle calldata badBundle,
        G1Point memory sharedKey,
        DleqProof memory proof
    ) external onlyRegistered onlyPhase(Phase.COMPLAINT) returns (ComplaintReturn) {
        // Make sure dealer is well registered
        uint32 complainerIdx = indexOfSender();
        uint32 dealerIdx = addressIndex[dealer];
        if (dealerIdx == 0) {
            evictParticipant(msg.sender, complainerIdx);
            return ComplaintReturn.InvalidDealerIdx;
        }
        // Compare the hashes compared to bundle provided
        uint256 expectedHash = dealHashes[dealerIdx];
        uint256 givenHash = hashDealBundle(badBundle);
        if (expectedHash != givenHash) {
            evictParticipant(msg.sender, complainerIdx);
            return ComplaintReturn.InvalidHash;
        }
        // Verify the dleq proof:
        // first base is the public key submitted during registration
        // second base is the shared key that complainers is putting here
        // both should have same dlog
        if (Bn128.dleqverify(pubkeys[dealer], sharedKey, proof, COMPLAINT_LABEL) == false) {
            evictParticipant(msg.sender, complainerIdx);
            return ComplaintReturn.InvalidDleq;
        }

        // Decrypt the share
        uint256 hashed = uint256(sha256(abi.encodePacked(sharedKey.x, sharedKey.y)));
        // indices start at value 1 so offset by one when referring in the array
        uint256 cipher = badBundle.encryptedShares[complainerIdx - 1];
        uint256 share = hashed ^ cipher;
        // Verify it is consistent with the polynomial setup by the dealer
        G1Point memory eval1 = Bn128.public_poly_eval(badBundle.commitment, uint256(complainerIdx));
        G1Point memory eval2 = Bn128.scalarMultiply(Bn128.g1(), share);
        if (Bn128.g1Equal(eval1, eval2) == true) {
            // the share is as expected, that means the complainer issued a complaint
            // for a valid deal. That means the complainer is gonna get excluded.
            // TODO evict complainer here
            evictParticipant(msg.sender, complainerIdx);
            return ComplaintReturn.InvalidConsistentShare;
        }

        // the complaint is valid, i.e. the deal is invalid as the share is not
        // consistent with the polynomial evaluation. We need to evict the dealer.
        evictParticipant(dealer, dealerIdx);
        return ComplaintReturn.ValidComplaint;
    }

    /// evicts a participant from the qualified set of participants. It emits an
    /// event giving the index so that offchain nodes can compute the final distributed
    /// key correctly.
    function evictParticipant(address p, uint32 index) private {
        delete addressIndex[p];
        delete dealHashes[index];
        delete pubkeys[p];
        emit EvictedParticipant(p, index);
    }

    function numberParticipants() public view returns (uint256) {
        return nbRegistered;
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

    function emitDealBundle(uint32 dealerIdx, DealBundle memory _bundle) private {
        emit DealBundleSubmitted(dealerIdx, _bundle);
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

    /// @notice returns the hash of a deal bundle. Hash is stored at the sharing phase
    /// and is checked at the complaint phase.
    function hashDealBundle(DealBundle memory db) public pure returns (uint256) {
        /// XXX is there no hope of flattening the structs without costs ?
        /// maybe with for loop over abi.encodePacked(previousEncoding, commit[i]) ?
        uint256[2][] memory flatten = new uint256[2][](db.commitment.length);
        for (uint256 i = 0; i < db.commitment.length; i++) {
            flatten[i] = [db.commitment[i].x, db.commitment[i].y];
        }
        return uint256(keccak256(abi.encodePacked(db.encryptedShares, flatten)));
    }
}
