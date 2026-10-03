// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;

import "./Token.sol";
import "./IdentityRegistry.sol";
import "./DataTypes.sol";

contract ConsentManager {
    struct ConsentRecord {
        address owner;
        address requester;
        DataType level;
        uint256 expiryDate;
        string purpose;
        bool isActive;
    }

    IdentityRegistry public identityRegistry;
    Token public token;

    // Mapping: user => (requester => ConsentRecord)
    mapping(address => mapping(address => ConsentRecord)) public consentRecords;

    event ConsentGranted(address indexed user, address indexed requester, uint256 expiryDate);
    event ConsentRevoked(address indexed user, address indexed requester);

    constructor(address _identityRegistryAddress, address _tokenAddress) {
        identityRegistry = IdentityRegistry(_identityRegistryAddress);
        token = Token(_tokenAddress);
    }

    // User grants permission to a specific requester
    function createConsent(address requester, DataType level, uint256 durationInSeconds, string calldata purpose) external {
        (bool exists, , ) = identityRegistry.identities(msg.sender);
        require(exists, "owner not registered");
        require(identityRegistry.registeredRequesters(requester), "requester not registered");
        require(durationInSeconds >= 1 days && durationInSeconds <= 365 days, "duration out of range");
        bool rewardDue = block.timestamp > consentRecords[msg.sender][requester].expiryDate;

        uint256 expiry = block.timestamp + durationInSeconds;

        consentRecords[msg.sender][requester] = ConsentRecord({
            owner: msg.sender,
            requester: requester,
            level: level,
            expiryDate: expiry,
            purpose: purpose,
            isActive: true
        });
        
        if (rewardDue) {
            token.mint(msg.sender, 1);
        }

        emit ConsentGranted(msg.sender, requester, expiry);
    }

    // User revokes permission early
    function revokeConsent(address requester) external {
        consentRecords[msg.sender][requester].isActive = false;
        emit ConsentRevoked(msg.sender, requester);
    }

    // DataSharing contract will call this to verify permissions
    function checkPermission(address requester, address user, DataType requiredLevel) external view returns (bool) {
        if (!identityRegistry.registeredRequesters(requester)){
            return false;
        }
        
        ConsentRecord memory record = consentRecords[user][requester];

        if (!record.isActive || block.timestamp > record.expiryDate) {
            return false;
        }

        // returns true if the level of access is higher than the required, see enum datatypes
        return uint8(record.level) >= uint8(requiredLevel);
    }
}