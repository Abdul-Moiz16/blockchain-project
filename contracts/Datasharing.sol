// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;


import "./ConsentManager.sol"; 
import "./DataTypes.sol";

contract DataSharing {

    // A state variable pointing to the deployed ConsentManager contract
    ConsentManager public immutable consentManager;

    struct LogEntry {
        address requester;
        address user;
        DataType level;
        uint64 timestamp;
        bool result;
        bytes32 envelopeHash;
    }

   
    LogEntry[] public accessLog;

    event AccessRequested(address indexed requester, address indexed user, DataType level, bool result, bytes32 ticket);
    
    // The constructor links this contract to the ConsentManager upon deployment
    constructor(address _consentManagerAddress) {
        consentManager = ConsentManager(_consentManagerAddress);
    }

    // Requester asks for access to a user's data
    function requestAccess(address user, DataType level) external returns (bytes32) {

        bool isAllowed = consentManager.checkPermission(msg.sender, user, level);

        bytes32 Ticket;

        if (isAllowed) {
            Ticket = keccak256(abi.encodePacked(msg.sender, user, level, block.timestamp));
        } else {
            Ticket = bytes32(0);
        }


        _writeLogEntry(msg.sender, user, level, uint64(block.timestamp), isAllowed, Ticket);
        

        emit AccessRequested(msg.sender, user, level, isAllowed, Ticket);        
        return Ticket;
    }

    function _writeLogEntry(
        address requester, 
        address user, 
        DataType level, 
        uint64 time, 
        bool result, 
        bytes32 envelopeHash
    ) private {
        accessLog.push(LogEntry({
            requester: requester,
            user: user,
            level: level,
            timestamp: time,
            result: result,
            envelopeHash: envelopeHash
        }));
    }
}