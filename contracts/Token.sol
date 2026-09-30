// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;

contract Token {
    address public owner; 
    
    mapping(address => uint256) public balanceOf;
    
    // will become consent manager so he can mint coins himself
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // transfers and minting still need to be implemented 
}