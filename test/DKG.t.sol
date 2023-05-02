// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {
    DealBundle,
    IDKG,
    DKG,
    NotAuthorized,
    NotRegistered,
    AlreadyRegistered,
    ParticipantLimit,
    InvalidPhase,
    InvalidSharesCount,
    InvalidCommitmentsCount
} from "../src/DKG.sol";
import {DKGFactory} from "../src/DKGFactory.sol";
import {Bn128, G1Point, DleqProof} from "../src/Bn128.sol";
import "forge-std/Test.sol";

contract DKGTest is Test {
    DKG private dkg;
    DKGFactory private factory;
    G1Point private p1;
    FakeDleq private fakeProof;

    function setUp() public {
        factory = new DKGFactory();
        dkg = new DKG(factory);
        p1 = randomPoint(1);
        fakeProof = fakeDleq();
    }

    struct FakeDleq {
        G1Point g1;
        G1Point g2;
        DleqProof proof;
    }

    function fakeDleq() public view returns (FakeDleq memory) {
        uint256 f =
            21888242871839275222246405745257275088548364400416034343698204186575808495133;
        uint256 e =
            21888242871839275222246405745257275088548364400416034343698204186575808495134;
        G1Point memory g1 = Bn128.scalarMultiply(Bn128.g1(), f);
        G1Point memory g2 =
            Bn128.scalarMultiply(Bn128.scalarMultiply(Bn128.g1(), e), f);
        return FakeDleq(g1, g2, DleqProof(f, e));
    }

    function emptyDealBundle() private pure returns (DealBundle memory) {
        uint256[] memory encryptedShares;
        G1Point[] memory commitment;
        return DealBundle(encryptedShares, commitment);
    }

    function randomPoint(uint256 offset)
        private
        view
        returns (G1Point memory)
    {
        uint256 fr = 19542123975320942039841207452351244 + offset;
        return Bn128.scalarMultiply(Bn128.g1(), fr);
    }

    function testRegister() public {
        assertEq(dkg.numberParticipants(), 0);
        for (uint256 i = 0; i < dkg.MAX_PARTICIPANTS(); i++) {
            address nextParticipant = address(uint160(i + 1));
            G1Point memory nextKey = randomPoint(i + 1);
            factory.addAuthorizedNode(nextParticipant);
            vm.prank(nextParticipant);
            dkg.registerParticipant(nextKey);
            assertEq(dkg.numberParticipants(), i + 1);
        }
    }

    function testHashingDealBundle() public view {
        DealBundle memory db = emptyDealBundle();
        dkg.hashDealBundle(db);
    }

    function testCannotRegisterIfNotAuthorized() public {
        address nextParticipant = address(uint160(1));
        vm.prank(nextParticipant);
        vm.expectRevert(NotAuthorized.selector);
        dkg.registerParticipant(p1);
    }

    function testCannotRegisterIfIncorrectPhase() public {
        address nextParticipant = address(uint160(1));
        factory.addAuthorizedNode(nextParticipant);
        vm.roll(dkg.registrationTime());
        vm.prank(nextParticipant);
        vm.expectRevert(InvalidPhase.selector);
        dkg.registerParticipant(p1);
    }

    function testCannotRegisterMoreThanMaxParticipants() public {
        address nextParticipant;
        for (uint256 i = 0; i < dkg.MAX_PARTICIPANTS(); i++) {
            nextParticipant = address(uint160(i + 1));
            G1Point memory p = randomPoint(i + 1);
            factory.addAuthorizedNode(nextParticipant);
            vm.prank(nextParticipant);
            dkg.registerParticipant(p);
        }
        nextParticipant = address(uint160(dkg.MAX_PARTICIPANTS()));
        factory.addAuthorizedNode(nextParticipant);
        vm.prank(nextParticipant);
        vm.expectRevert(ParticipantLimit.selector);
        dkg.registerParticipant(p1);
    }

    function testCannotRegisterMoreThanOnce() public {
        address nextParticipant = address(uint160(1));
        factory.addAuthorizedNode(nextParticipant);

        vm.prank(nextParticipant);
        dkg.registerParticipant(p1);

        G1Point memory p2 = randomPoint(10);
        vm.expectRevert(AlreadyRegistered.selector);
        vm.prank(nextParticipant);
        dkg.registerParticipant(p2);
    }

    function testSubmitDealBundle() public {
        // TODO
    }

    function testCannotSubmitDealBundleIfNotRegistered() public {
        address nextParticipant = address(uint160(1));

        vm.prank(nextParticipant);
        vm.expectRevert(NotRegistered.selector);
        dkg.submitDealBundle(emptyDealBundle());
    }

    function testCannotSubmitDealBundleIfInvalidPhase() public {
        address nextParticipant = address(uint160(1));
        factory.addAuthorizedNode(nextParticipant);
        vm.prank(nextParticipant);
        dkg.registerParticipant(p1);

        vm.roll(dkg.dealTime());
        vm.prank(nextParticipant);
        vm.expectRevert(InvalidPhase.selector);
        dkg.submitDealBundle(emptyDealBundle());
    }

    function testCannotSubmitDealBundleWithInvalidSharesCount() public {
        address nextParticipant = address(uint160(1));
        factory.addAuthorizedNode(nextParticipant);
        vm.prank(nextParticipant);
        dkg.registerParticipant(p1);

        DealBundle memory bundle = emptyDealBundle();
        bundle.encryptedShares = new uint256[](2); // bundle with 2 shares

        vm.roll(dkg.registrationTime());
        vm.prank(nextParticipant);
        vm.expectRevert(InvalidSharesCount.selector);
        dkg.submitDealBundle(bundle);
    }

    function testCannotSubmitDealBundleWithInvalidCommitmentsCount() public {
        address nextParticipant = address(uint160(1));
        factory.addAuthorizedNode(nextParticipant);
        vm.prank(nextParticipant);
        dkg.registerParticipant(p1);

        DealBundle memory bundle = emptyDealBundle();
        bundle.encryptedShares = new uint256[](1); // bundle with 1 share and 0 commitments

        vm.roll(dkg.registrationTime());
        vm.prank(nextParticipant);
        vm.expectRevert(InvalidCommitmentsCount.selector);
        dkg.submitDealBundle(bundle);
    }

    function testCannotSubmitComplaintBundleIfNotRegistered() public {
        address nextParticipant = address(uint160(1));
        DealBundle memory bundle = emptyDealBundle();
        vm.prank(nextParticipant);
        vm.expectRevert(NotRegistered.selector);
        dkg.submitComplaintBundle(
            address(uint160(2)), bundle, p1, fakeProof.proof
        );
    }

    function testCannotSubmitComplaintBundleIfInvalidPhase() public {
        address nextParticipant = address(uint160(1));
        factory.addAuthorizedNode(nextParticipant);
        vm.prank(nextParticipant);
        dkg.registerParticipant(p1);
        vm.roll(dkg.complaintTime());
        vm.prank(nextParticipant);
        DealBundle memory bundle = emptyDealBundle();
        vm.expectRevert(InvalidPhase.selector);
        dkg.submitComplaintBundle(
            address(uint160(2)), bundle, p1, fakeProof.proof
        );
    }

    function testCannotSubmitCOmplaintWithInvalidBundle() public {
        address nextParticipant = address(uint160(1));
        factory.addAuthorizedNode(nextParticipant);
        vm.prank(nextParticipant);
        dkg.registerParticipant(p1);
        // go to DKG phase by going to the time registration ends
        vm.roll(dkg.registrationTime());
        vm.prank(nextParticipant);
    }
}
