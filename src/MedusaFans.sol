// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {BN254EncryptionOracle as Oracle} from "./BN254EncryptionOracle.sol";
import {IEncryptionClient, Ciphertext} from "./EncryptionOracle.sol";
import {G1Point} from "./Bn128.sol";
import {PullPayment} from "@openzeppelin/contracts/security/PullPayment.sol";

error CallbackNotAuthorized();
error ListingDoesNotExist();
error InsufficentFunds();

struct Listing {
    address seller;
    uint256 price;
    string uri;
}

contract MedusaFans is IEncryptionClient, PullPayment {
    /// @notice The Encryption Oracle Instance
    Oracle public oracle;

    /// @notice A mapping from cipherId to listing
    mapping(uint256 => Listing) public listings;

    event ListingDecryption(uint256 indexed requestId, Ciphertext ciphertext);
    event NewListing(
        address indexed seller, uint256 indexed cipherId, string name, string description, uint256 price, string uri
    );
    event NewSale(address indexed buyer, address indexed seller, uint256 requestId, uint256 cipherId);

    modifier onlyOracle() {
        if (msg.sender != address(oracle)) {
            revert CallbackNotAuthorized();
        }
        _;
    }

    constructor(Oracle _oracle) {
        oracle = _oracle;
    }

    /// @notice Create a new listing
    /// @dev Submits a ciphertext to the oracle, stores a listing, and emits an event
    /// @return cipherId The id of the ciphertext associated with the new listing
    function createListing(
        Ciphertext calldata cipher,
        string calldata name,
        string calldata description,
        uint256 price,
        string calldata uri
    ) external returns (uint256) {
        uint256 cipherId = oracle.submitCiphertext(cipher, msg.sender);
        listings[cipherId] = Listing(msg.sender, price, uri);
        emit NewListing(msg.sender, cipherId, name, description, price, uri);
        return cipherId;
    }

    /// @notice Pay for a listing
    /// @dev Buyer pays the price for the listing, which can be withdrawn by the seller later; emits an event
    /// @return requestId The id of the reencryption request associated with the purchase
    function buyListing(uint256 cipherId, G1Point calldata buyerPublicKey) external payable returns (uint256) {
        Listing memory listing = listings[cipherId];
        if (listing.seller == address(0)) {
            revert ListingDoesNotExist();
        }
        if (msg.value < listing.price) {
            revert InsufficentFunds();
        }
        _asyncTransfer(listing.seller, msg.value);
        uint256 requestId = oracle.requestReencryption(cipherId, buyerPublicKey);
        emit NewSale(msg.sender, listing.seller, requestId, cipherId);
        return requestId;
    }

    /// @inheritdoc IEncryptionClient
    function oracleResult(uint256 requestId, Ciphertext calldata cipher) external onlyOracle {
        emit ListingDecryption(requestId, cipher);
    }

    /// @notice Convenience function to get the public key of the oracle
    /// @dev This is the public key that sellers should use to encrypt their listing ciphertext
    /// @dev Note: This feels like a nice abstraction, but it's not strictly necessary
    function publicKey() external view returns (G1Point memory) {
        return oracle.distributedKey();
    }
}
