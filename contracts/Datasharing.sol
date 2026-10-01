// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;


import "./ConsentManager.sol"; 

contract DataSharing {
    // A state variable pointing to the deployed ConsentManager contract
    ConsentManager public consentManager;

    struct LogEntry {
        address requester;
        address user;
        uint256 timestamp;
        bool accessGranted;
    }

    // The access log from your UML
    LogEntry[] public accessLog;

    event AccessRequested(address indexed requester, address indexed user, bool result);

    // The constructor links this contract to the ConsentManager upon deployment
    constructor(address _consentManagerAddress) {
        consentManager = ConsentManager(_consentManagerAddress);
    }

    // Requester asks for access to a user's data
    function requestAccess(address user) external returns (bool) {
        // 1. Cross-contract call: Ask ConsentManager if msg.sender is allowed
        bool isAllowed = consentManager.checkPermission(msg.sender, user);

        // 2. Write the log entry (recording both successes and failures)
        accessLog.push(LogEntry({
            requester: msg.sender,
            user: user,
            timestamp: block.timestamp,
            accessGranted: isAllowed
        }));

        emit AccessRequested(msg.sender, user, isAllowed);

        // 3. Return the result (In the full UML, this would generate the EphemeralTicket)
        return isAllowed;
    }
}