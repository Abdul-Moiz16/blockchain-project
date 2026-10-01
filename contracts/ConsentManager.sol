// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;

import "./Token.sol";
import "./IdentityRegistry.sol";

contract ConsentManager {
    struct ConsentRecord {
        uint256 expiryDate;
        bool isActive;
    }

    // Mapping: user => (requester => ConsentRecord)
    mapping(address => mapping(address => ConsentRecord)) public consentRecords;

    event ConsentGranted(address indexed user, address indexed requester, uint256 expiryDate);
    event ConsentRevoked(address indexed user, address indexed requester);

    // User grants permission to a specific requester
    function createConsent(address requester, uint256 durationInSeconds) external {
        uint256 expiry = block.timestamp + durationInSeconds;
        
        consentRecords[msg.sender][requester] = ConsentRecord({
            expiryDate: expiry,
            isActive: true
        });
        
        emit ConsentGranted(msg.sender, requester, expiry);
    }

    // User revokes permission early
    function revokeConsent(address requester) external {
        consentRecords[msg.sender][requester].isActive = false;
        emit ConsentRevoked(msg.sender, requester);
    }

    // DataSharing contract will call this to verify permissions
    function checkPermission(address requester, address user) external view returns (bool) {
        ConsentRecord memory record = consentRecords[user][requester];
        return (record.isActive && block.timestamp <= record.expiryDate);
    }
}