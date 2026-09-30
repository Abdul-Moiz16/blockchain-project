// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;


contract IdentityRegistry {
    address public administrator;
    
    // These are all the actors
    mapping(address => bool) public registeredUsers;
    mapping(address => bool) public registeredRequesters;
    mapping(address => bool) public registeredAttestors;
    
    
    struct Attestation {
        bytes32 claimHash;
        uint256 expiry; 
    }

    mapping(address => Attestation) public attestations;
    
    constructor() {
        administrator = msg.sender;
    }

    // add registeruser, addrequestor, addattestor and storeattestation 
    
}