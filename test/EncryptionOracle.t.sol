// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {
    Ciphertext,
    EncryptionOracle,
    IEncryptionOracle,
    IEncryptionClient,
    RequestDoesNotExist,
    OracleResultFailed
} from "../src/EncryptionOracle.sol";
import {Suite} from "../src/OracleFactory.sol";
import {G1Point, DleqProof, Bn128} from "../src/Bn128.sol";

contract MockEncryptionOracle is EncryptionOracle {
    constructor(G1Point memory _distKey) EncryptionOracle(_distKey) {}

    function suite() external pure override returns (Suite) {
        return Suite.BN254_KEYG1_HGAMAL;
    }
}

contract MockEncryptionClient is IEncryptionClient {
    bool private shouldRevert;

    constructor(bool _shouldRevert) {
        shouldRevert = _shouldRevert;
    }

    function oracleResult(uint256 requestId, Ciphertext memory _cipher) external {
        if (shouldRevert) {
            revert("I messed up");
        }
    }
}

contract EncryptionOracleTest is Test {
    MockEncryptionOracle oracle;

    event NewCiphertext(uint256 indexed id, Ciphertext ciphertext, bytes link, address client);
    event ReencryptionRequest(uint256 indexed cipherId, uint256 requestId, G1Point publicKey, address client);

    function setUp() public {
        oracle = new MockEncryptionOracle(dummyPublicKey());
    }

    function dummyCiphertext() private pure returns (Ciphertext memory) {
        return Ciphertext(G1Point(12345, 12345), 98765, G1Point(1, 2), DleqProof(1, 2));
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

    function testSubmitCipherText() public {
        //Ciphertext memory cipher = dummyCiphertext();
        //vm.expectEmit(true, false, false, true);
        //emit NewCiphertext(1, cipher, "dummyLink", address(this));
        //uint256 cipherId = oracle.submitCiphertext(
        //    cipher,
        //    "dummyLink",
        //    address(this)
        //);
        //assertEq(cipherId, 1);
        //cipherId = oracle.submitCiphertext(
        //    cipher,
        //    "otherDummyLink",
        //    address(this)
        //);
        //assertEq(cipherId, 2);
    }

    function testRequestReencryption() public {
        G1Point memory publicKey = dummyPublicKey();
        uint256 randomCipherId = 123312;

        vm.expectEmit(true, false, false, true);
        emit ReencryptionRequest(randomCipherId, 1, publicKey, address(this));
        uint256 requestId = oracle.requestReencryption(randomCipherId, publicKey);
        assertEq(requestId, 1);

        uint256 otherRandomCipherId = 45687456;
        vm.expectEmit(true, false, false, true);
        emit ReencryptionRequest(otherRandomCipherId, 2, publicKey, address(this));
        requestId = oracle.requestReencryption(otherRandomCipherId, publicKey);
        assertEq(requestId, 2);
    }

    function testDeliverReencryption() public {
        Ciphertext memory cipher = dummyCiphertext();

        G1Point memory publicKey = dummyPublicKey();
        uint256 randomCipherId = 123312;
        MockEncryptionClient client = new MockEncryptionClient(false);

        vm.prank(address(client));
        uint256 requestId = oracle.requestReencryption(randomCipherId, publicKey);
        bool result = oracle.deliverReencryption(requestId, cipher);
        assert(result);
    }

    function testCannotDeliverReencryptionIfRequestDoesNotExist() public {
        Ciphertext memory cipher = dummyCiphertext();
        uint256 randomRequestId = 123312;

        vm.expectRevert(RequestDoesNotExist.selector);
        oracle.deliverReencryption(randomRequestId, cipher);
    }

    function testCannotDeliverReencryptionIfOracleResultNotSupported() public {
        Ciphertext memory cipher = dummyCiphertext();

        G1Point memory publicKey = dummyPublicKey();
        uint256 randomCipherId = 123312;

        uint256 requestId = oracle.requestReencryption(randomCipherId, publicKey);
        vm.expectRevert(
            abi.encodeWithSelector(OracleResultFailed.selector, "Client does not support oracleResult() method")
        );
        oracle.deliverReencryption(requestId, cipher);
    }

    function testCannotDeliverReencryptionIfOracleResultReverts() public {
        Ciphertext memory cipher = dummyCiphertext();

        G1Point memory publicKey = dummyPublicKey();
        uint256 randomCipherId = 123312;

        MockEncryptionClient client = new MockEncryptionClient(true);

        vm.prank(address(client));
        uint256 requestId = oracle.requestReencryption(randomCipherId, publicKey);
        vm.expectRevert(abi.encodeWithSelector(OracleResultFailed.selector, "I messed up"));
        oracle.deliverReencryption(requestId, cipher);
    }

    function testDistributedKey() public {
        G1Point memory distKey = oracle.distributedKey();
        G1Point memory expectedKey = dummyPublicKey();

        assertEq(distKey.x, expectedKey.x);
        assertEq(distKey.y, expectedKey.y);
    }
}
