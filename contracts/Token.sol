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

    event Mint(address indexed to, uint256 amount);

    
    function mint(address to, uint256 amount) external onlyOwner {
        balanceOf[to] += amount;
        emit Mint(to, amount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }


}