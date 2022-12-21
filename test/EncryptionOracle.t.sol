// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {
    Ciphertext,
    PendingRequest,
    EncryptionOracle,
    IEncryptionOracle,
    IEncryptionClient,
    RequestDoesNotExist,
    OracleResultFailed,
    NotRelayer,
    NotRelayerOrOwner,
    ReencryptedCipher
} from "../src/EncryptionOracle.sol";
import {Suite} from "../src/OracleFactory.sol";
import {G1Point, DleqProof, Bn128} from "../src/Bn128.sol";

contract MockEncryptionOracle is EncryptionOracle {
    constructor(G1Point memory _distKey, address _relayer) EncryptionOracle(_distKey, _relayer) {}

    function suite() external pure override returns (Suite) {
        return Suite.BN254_KEYG1_HGAMAL;
    }
}

contract MockEncryptionClient is IEncryptionClient {
    bool private shouldRevert;

    constructor(bool _shouldRevert) {
        shouldRevert = _shouldRevert;
    }

    function oracleResult(uint256 requestId, ReencryptedCipher memory _cipher) external {
        if (shouldRevert) {
            revert("I messed up");
        }
    }
}

contract MockReentrantRelayer {
    receive() external payable {
        IEncryptionOracle oracle = IEncryptionOracle(msg.sender);
        uint256 requestId = 1;
        (, uint96 gasReimbursement) = oracle.pendingRequests(requestId);

        // While the oracle's balance is greater than the request's gas reimbursement,
        // keep calling oracle.deliverReencryption until the oracle's funds are drained.
        while (msg.sender.balance >= gasReimbursement) {
            oracle.deliverReencryption(requestId, ReencryptedCipher(G1Point(1, 2), 3));
        }
    }
}

contract EncryptionOracleTest is Test {
    MockEncryptionOracle oracle;
    address relayer = makeAddr("relayer");

    event NewCiphertext(uint256 indexed id, Ciphertext ciphertext, address client);
    event ReencryptionRequest(uint256 indexed cipherId, uint256 requestId, G1Point publicKey, PendingRequest request);

    function setUp() public {
        oracle = new MockEncryptionOracle(dummyPublicKey(), relayer);
    }

    function dummyCiphertext() private pure returns (Ciphertext memory) {
        return Ciphertext(G1Point(12345, 12345), 98765, G1Point(1, 2), DleqProof(1, 2));
    }

    function dummyReencryption() private pure returns (ReencryptedCipher memory) {
        return cipher2Reenc(dummyCiphertext());
    }

    function cipher2Reenc(Ciphertext memory c) private pure returns (ReencryptedCipher memory) {
        ReencryptedCipher memory rc = ReencryptedCipher(c.random, c.cipher);
        return rc;
    }

    function dummyPublicKey() private pure returns (G1Point memory) {
        return G1Point(23476, 23478);
    }

    function testPause() public {
        assertFalse(oracle.paused());
        oracle.pause();
        assertTrue(oracle.paused());
    }

    function testCannotPauseIfNotOwner() public {
        address notOwner = makeAddr("notOwner");
        vm.expectRevert("Ownable: caller is not the owner");
        hoax(notOwner);

        oracle.pause();
        assertFalse(oracle.paused());
    }

    function testUnpause() public {
        oracle.pause();
        assertTrue(oracle.paused());

        oracle.unpause();
        assertFalse(oracle.paused());
    }

    function testCannotUnpauseIfNotOwner() public {
        oracle.pause();
        assertTrue(oracle.paused());

        address notOwner = makeAddr("notOwner");
        vm.expectRevert("Ownable: caller is not the owner");
        hoax(notOwner);

        oracle.unpause();
        assertTrue(oracle.paused());
    }

    function testUpdateRelayer() public {
        address newRelayer = makeAddr("newRelayer");
        vm.prank(relayer);
        oracle.updateRelayer(newRelayer);
        assertEq(oracle.relayer(), newRelayer);

        address otherNewRelayer = makeAddr("otherNewRelayer");
        vm.prank(oracle.owner());
        oracle.updateRelayer(otherNewRelayer);
        assertEq(oracle.relayer(), otherNewRelayer);
    }

    function testCannotUpdateRelayerIfNotRelayerOrOwner() public {
        address notRelayerOrOwner = makeAddr("notRelayerOrOwner");
        vm.expectRevert(NotRelayerOrOwner.selector);
        vm.prank(notRelayerOrOwner);

        oracle.updateRelayer(notRelayerOrOwner);
        assertEq(oracle.relayer(), relayer);
    }

    function testSubmitCipherText() public {
        /// @custom:todo implement DLEQ valid proof for it
        // Ciphertext memory cipher = dummyCiphertext();
        // vm.expectEmit(true, false, false, true);
        // emit NewCiphertext(1, cipher, address(this));
        // uint256 cipherId = oracle.submitCiphertext(cipher, address(this));
        // assertEq(cipherId, 1);
        // cipherId = oracle.submitCiphertext(cipher, address(this));
        // assertEq(cipherId, 2);
    }

    function testRequestReencryption() public {
        G1Point memory publicKey = dummyPublicKey();
        uint256 randomCipherId = 123312;
        uint96 gasReimbursement = 1 ether;

        vm.expectEmit(true, false, false, true);
        emit ReencryptionRequest(randomCipherId, 1, publicKey, PendingRequest(address(this), gasReimbursement));
        uint256 requestId = oracle.requestReencryption{value: gasReimbursement}(randomCipherId, publicKey);
        assertEq(requestId, 1);

        uint256 otherRandomCipherId = 45687456;
        vm.expectEmit(true, false, false, true);
        emit ReencryptionRequest(otherRandomCipherId, 2, publicKey, PendingRequest(address(this), gasReimbursement));
        requestId = oracle.requestReencryption{value: gasReimbursement}(otherRandomCipherId, publicKey);
        assertEq(requestId, 2);
    }

    function testDeliverReencryption() public {
        Ciphertext memory cipher = dummyCiphertext();

        G1Point memory publicKey = dummyPublicKey();
        uint256 randomCipherId = 123312;
        uint96 gasReimbursement = 1 ether;
        MockEncryptionClient client = new MockEncryptionClient(false);
        vm.deal(address(client), gasReimbursement);

        vm.prank(address(client));
        uint256 requestId = oracle.requestReencryption{value: gasReimbursement}(randomCipherId, publicKey);

        uint256 relayerBalanceBefore = relayer.balance;
        vm.prank(relayer);
        bool result = oracle.deliverReencryption(requestId, cipher2Reenc(cipher));
        assert(result);
        assert(relayer.balance == relayerBalanceBefore + gasReimbursement);
    }

    function testCannotDeliverReencryptionIfNotRelayer() public {
        ReencryptedCipher memory cipher = dummyReencryption();
        uint256 randomRequestId = 123312;

        vm.expectRevert(NotRelayer.selector);
        oracle.deliverReencryption(randomRequestId, cipher);
    }

    function testCannotDeliverReencryptionIfRequestDoesNotExist() public {
        ReencryptedCipher memory cipher = dummyReencryption();
        uint256 randomRequestId = 123312;

        vm.expectRevert(RequestDoesNotExist.selector);
        vm.prank(relayer);
        oracle.deliverReencryption(randomRequestId, cipher);
    }

    function testCannotDeliverReencryptionIfOracleResultNotSupported() public {
        ReencryptedCipher memory cipher = dummyReencryption();

        G1Point memory publicKey = dummyPublicKey();
        uint256 randomCipherId = 123312;

        uint256 requestId = oracle.requestReencryption(randomCipherId, publicKey);
        vm.expectRevert(
            abi.encodeWithSelector(OracleResultFailed.selector, "Client does not support oracleResult() method")
        );
        vm.prank(relayer);
        oracle.deliverReencryption(requestId, cipher);
    }

    function testCannotDeliverReencryptionIfOracleResultReverts() public {
        ReencryptedCipher memory cipher = dummyReencryption();

        G1Point memory publicKey = dummyPublicKey();
        uint256 randomCipherId = 123312;

        MockEncryptionClient client = new MockEncryptionClient(true);

        vm.prank(address(client));
        uint256 requestId = oracle.requestReencryption(randomCipherId, publicKey);
        vm.expectRevert(abi.encodeWithSelector(OracleResultFailed.selector, "I messed up"));
        vm.prank(relayer);
        oracle.deliverReencryption(requestId, cipher);
    }

    function testCannotDeliverReencryptionWithReentrantAttack() public {
        MockReentrantRelayer reentrantRelayer = new MockReentrantRelayer();
        oracle = new MockEncryptionOracle(
            dummyPublicKey(),
            address(reentrantRelayer)
        );
        Ciphertext memory cipher = dummyCiphertext();

        G1Point memory publicKey = dummyPublicKey();
        uint256 randomCipherId = 123312;
        uint96 gasReimbursement = 1 ether;
        MockEncryptionClient client = new MockEncryptionClient(false);
        vm.deal(address(client), gasReimbursement);

        vm.prank(address(client));
        uint256 requestId = oracle.requestReencryption{value: gasReimbursement}(randomCipherId, publicKey);

        uint256 relayerBalanceBefore = relayer.balance;
        vm.expectRevert(abi.encodeWithSelector(OracleResultFailed.selector, "Failed to send gas reimbursement"));
        vm.prank(address(reentrantRelayer));
        oracle.deliverReencryption(requestId, cipher2Reenc(cipher));
        assert(relayer.balance == relayerBalanceBefore);
    }

    function testDistributedKey() public {
        G1Point memory distKey = oracle.distributedKey();
        G1Point memory expectedKey = dummyPublicKey();

        assertEq(distKey.x, expectedKey.x);
        assertEq(distKey.y, expectedKey.y);
    }
}
