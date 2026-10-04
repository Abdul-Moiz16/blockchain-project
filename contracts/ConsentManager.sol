// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;

import "./Token.sol";
import "./IdentityRegistry.sol";
import "./DataTypes.sol";

contract ConsentManager {
    struct ConsentRecord {
        DataType level;
        uint64 expiryDate;
        bool isActive;
        string purpose;
    }

    // make the two addresses to the other smart contracts immutable
    IdentityRegistry public immutable identityRegistry;
    Token public immutable token;

    // Mapping: user => (requester => ConsentRecord)
    mapping(address => mapping(address => ConsentRecord)) public consentRecords;


    // making events so we can omit them. not actually used but good practice. (i think)
    event ConsentGranted(address indexed user, address indexed requester, uint256 expiryDate);
    event ConsentRevoked(address indexed user, address indexed requester);

    // immediatly give it the addresses of the other two smart contracts. 
    constructor(address _identityRegistryAddress, address _tokenAddress) {
        identityRegistry = IdentityRegistry(_identityRegistryAddress);
        token = Token(_tokenAddress);
    }

    // User grants permission to a specific requester
    function createConsent(address requester, DataType level, uint256 durationInSeconds, string calldata purpose) external {
        // this line only cares about if it exists. so only look at the first entry bool
        (bool exists, , ) = identityRegistry.identities(msg.sender);
        require(exists, "owner not registered");
        require(identityRegistry.registeredRequesters(requester), "requester not registered");
        require(durationInSeconds >= 1 days && durationInSeconds <= 365 days, "duration out of range");
        bool rewardDue = block.timestamp > consentRecords[msg.sender][requester].expiryDate;

        uint64 expiry = uint64(block.timestamp + durationInSeconds);

        // fill in the consent record with the given wished for levels. 
        consentRecords[msg.sender][requester] = ConsentRecord({
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
        
        ConsentRecord storage record = consentRecords[user][requester];

        if (!record.isActive || block.timestamp > record.expiryDate) {
            return false;
        }

        // returns true if the level of access is higher than the required, see enum datatypes
        return uint8(record.level) >= uint8(requiredLevel);
    }
}