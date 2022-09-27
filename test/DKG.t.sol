// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {
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
import {Bn128} from "../src/Bn128.sol";
import "forge-std/Test.sol";

contract DKGTest is Test {
    DKG private dkg;
    DKGFactory private factory;

    function setUp() public {
        factory = new DKGFactory();
        dkg = new DKG(factory);
    }

    function emptyDealBundle() private pure returns (DKG.DealBundle memory) {
        uint32[] memory indicies;
        uint256[] memory encryptedShares;
        Bn128.G1Point[] memory commitment;
        return DKG.DealBundle(Bn128.g1Zero(), indicies, encryptedShares, commitment);
    }

    function testRegister() public {
        assertEq(dkg.numberParticipants(), 0);
        for (uint256 i = 0; i < dkg.MAX_PARTICIPANTS(); i++) {
            address nextParticipant = address(uint160(i + 1));
            factory.addAuthorizedNode(nextParticipant);
            vm.prank(nextParticipant);
            dkg.registerParticipant(i + 1); // key != 0
            assertEq(dkg.numberParticipants(), i + 1);
        }
    }

    function testCannotRegisterIfNotAuthorized() public {
        address nextParticipant = address(uint160(1));
        vm.prank(nextParticipant);
        vm.expectRevert(NotAuthorized.selector);
        dkg.registerParticipant(1);
    }

    function testCannotRegisterIfIncorrectPhase() public {
        address nextParticipant = address(uint160(1));
        factory.addAuthorizedNode(nextParticipant);

        vm.roll(dkg.registrationTime());
        vm.prank(nextParticipant);
        vm.expectRevert(InvalidPhase.selector);
        dkg.registerParticipant(1);
    }

    function testCannotRegisterMoreThanMaxParticipants() public {
        address nextParticipant;
        for (uint256 i = 0; i < dkg.MAX_PARTICIPANTS(); i++) {
            nextParticipant = address(uint160(i + 1));
            factory.addAuthorizedNode(nextParticipant);
            vm.prank(nextParticipant);
            dkg.registerParticipant(i + 1); // key != 0
        }
        nextParticipant = address(uint160(dkg.MAX_PARTICIPANTS()));
        factory.addAuthorizedNode(nextParticipant);
        vm.prank(nextParticipant);
        vm.expectRevert(ParticipantLimit.selector);
        dkg.registerParticipant(1);
    }

    function testCannotRegisterMoreThanOnce() public {
        address nextParticipant = address(uint160(1));
        factory.addAuthorizedNode(nextParticipant);

        vm.prank(nextParticipant);
        dkg.registerParticipant(1);

        vm.expectRevert(AlreadyRegistered.selector);
        vm.prank(nextParticipant);
        dkg.registerParticipant(10);
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
        dkg.registerParticipant(1);

        vm.roll(dkg.dealTime());
        vm.prank(nextParticipant);
        vm.expectRevert(InvalidPhase.selector);
        dkg.submitDealBundle(emptyDealBundle());
    }

    function testCannotSubmitDealBundleWithInvalidSharesCount() public {
        address nextParticipant = address(uint160(1));
        factory.addAuthorizedNode(nextParticipant);
        vm.prank(nextParticipant);
        dkg.registerParticipant(1);

        DKG.DealBundle memory bundle = emptyDealBundle();
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
        dkg.registerParticipant(1);

        DKG.DealBundle memory bundle = emptyDealBundle();
        bundle.encryptedShares = new uint256[](1); // bundle with 1 share and 0 commitments

        vm.roll(dkg.registrationTime());
        vm.prank(nextParticipant);
        vm.expectRevert(InvalidCommitmentsCount.selector);
        dkg.submitDealBundle(bundle);
    }

    function testCannotSubmitDealBundleWithInvalidCommitment() public {
        // TODO
    }

    function testSubmitComplaintBundle() public {
        // TODO
    }

    function testCannotSubmitComplaintBundleIfNotRegistered() public {
        address nextParticipant = address(uint160(1));

        vm.prank(nextParticipant);
        vm.expectRevert(NotRegistered.selector);
        dkg.submitComplaintBundle();
    }

    function testCannotSubmitComplaintBundleIfInvalidPhase() public {
        address nextParticipant = address(uint160(1));
        factory.addAuthorizedNode(nextParticipant);
        vm.prank(nextParticipant);
        dkg.registerParticipant(1);

        vm.roll(dkg.complaintTime());
        vm.prank(nextParticipant);
        vm.expectRevert(InvalidPhase.selector);
        dkg.submitComplaintBundle();
    }
}
