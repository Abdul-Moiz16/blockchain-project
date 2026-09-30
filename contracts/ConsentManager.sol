// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;

import "./Token.sol";
import "./IdentityRegistry.sol";

contract ConsentManager {
    Token public tokenContract;
    IdentityRegistry public registryContract;
    
    mapping(bytes32 => ConsentRecord) public consentRecords;
    
    constructor(address _tokenAddress, address _registryAddress) {
        tokenContract = TokenPart(_tokenAddress);
        registryContract = IdentityRegistry(_registryAddress);
    }
    

    // implement giveconsent, revokeconsent, checkpermission
}