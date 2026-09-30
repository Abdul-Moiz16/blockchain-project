// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;


import "./ConsentManager.sol";

contract DataSharing {
    ConsentManager public consentManager;
    
    constructor(address _consentManagerAddress) {
        consentManager = ConsentManager(_consentManagerAddress);
    }
    
    // implement requestAccess
}