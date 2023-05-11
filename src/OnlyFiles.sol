// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity ^0.8.19;

import {
    MedusaClient,
    IEncryptionClient,
    IEncryptionOracle,
    Ciphertext,
    ReencryptedCipher,
    G1Point
} from "./MedusaClient.sol";
import {PullPayment} from "@openzeppelin/contracts/security/PullPayment.sol";

error ListingDoesNotExist();
error InsufficentFunds();

struct Listing {
    address seller;
    uint256 price;
    string uri;
}

contract OnlyFiles is MedusaClient, PullPayment {
    /// @notice A mapping from cipherId to listing
    mapping(uint256 => Listing) public listings;

    event ListingDecryption(
        uint256 indexed requestId, ReencryptedCipher reencryptedCipher
    );
    event NewListing(
        address indexed seller,
        uint256 indexed cipherId,
        Ciphertext ciphertext,
        string name,
        string description,
        uint256 price,
        string uri
    );
    event NewSale(
        address indexed buyer,
        address indexed seller,
        uint256 requestId,
        uint256 cipherId
    );

    constructor(IEncryptionOracle _oracle) MedusaClient(_oracle) {}

    /// @notice Create a new listing
    /// @dev Submits a ciphertext to the oracle, stores a listing, and emits an event
    /// @return cipherId The id of the ciphertext associated with the new listing
    function createListing(
        Ciphertext calldata cipher,
        string calldata name,
        string calldata description,
        uint256 price,
        string calldata uri
    ) external payable returns (uint256) {
        uint256 cipherId =
            oracle.submitCiphertext{value: msg.value}(cipher, msg.sender);
        listings[cipherId] = Listing(msg.sender, price, uri);
        emit NewListing(
            msg.sender, cipherId, cipher, name, description, price, uri
        );
        return cipherId;
    }

    /// @notice Pay for a listing
    /// @dev Buyer pays the price for the listing, which can be withdrawn by the seller later; emits an event
    /// @return requestId The id of the reencryption request associated with the purchase
    function buyListing(uint256 cipherId, G1Point calldata buyerPublicKey)
        external
        payable
        returns (uint256)
    {
        Listing memory listing = listings[cipherId];
        if (listing.seller == address(0)) {
            revert ListingDoesNotExist();
        }
        if (msg.value < listing.price) {
            revert InsufficentFunds();
        }

        _asyncTransfer(listing.seller, listing.price);
        uint256 requestId = oracle.requestReencryption{
            value: msg.value - listing.price
        }(cipherId, buyerPublicKey);

        emit NewSale(msg.sender, listing.seller, requestId, cipherId);
        return requestId;
    }

    function processOracleResult(
        uint256 requestId,
        ReencryptedCipher memory cipher
    ) internal override {
        emit ListingDecryption(requestId, cipher);
    }

    /// @notice Convenience function to get the public key of the oracle
    /// @dev This is the public key that sellers should use to encrypt their listing ciphertext
    /// @dev Note: This feels like a nice abstraction, but it's not strictly necessary
    function publicKey() external view returns (G1Point memory) {
        return oracle.distributedKey();
    }
}
