// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;

import "./Token.sol";
import "./IdentityRegistry.sol";

contract ConsentManager {
    Token public tokenContract;
    IdentityRegistry public registryContract;
    struct ConsentRecord {
        bool active;
        uint256 expiresAt;
    }

    mapping(address => mapping(address => mapping(DataType => ConsentRecord))) public consentRecords;

    constructor(address _tokenAddress, address _registryAddress) {
        tokenContract = Token(_tokenAddress);
        registryContract = IdentityRegistry(_registryAddress);
    }
    
           
    // implement giveconsent, revokeconsent, checkpermission
}