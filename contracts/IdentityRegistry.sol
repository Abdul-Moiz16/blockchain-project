// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;
import "./DataTypes.sol";



contract IdentityRegistry {
    address public immutable administrator;
    
    // These are all the actors
    struct Identity {
        bool exists;
        bytes32 identityHash;
        string offchainRef;
    }
    struct Attestation {
        bytes32 claimHash;
        uint256 expiry; 
    }

    mapping(address => Identity) public identities;
    mapping(address => bool) public registeredRequesters;
    mapping(address => bool) public registeredAttestors;
    mapping(address => mapping(DataType => Attestation)) public attestations;

    constructor() {
        administrator = msg.sender;
    }

    event UserRegistered(address indexed user, bytes32 identityHash);
    event Attested(address indexed owner, DataType scope, address indexed attestor, bytes32 claimHash, uint256 expiry);

    function registerUser(bytes32 identityHash, string calldata offchainRef) external {
        require(!identities[msg.sender].exists, "already registered");
        identities[msg.sender] = Identity(true, identityHash, offchainRef);
        emit UserRegistered(msg.sender, identityHash);
    }

    modifier onlyAdmin() {
        require(msg.sender == administrator, "not admin");
        _;
    }

    modifier onlyAttestor() {
        require(registeredAttestors[msg.sender], "not attestor");
        _;
    }

    function registerAttestor(address attestor) external onlyAdmin {
        registeredAttestors[attestor] = true;
    }   

    function registerRequester(address requester) external onlyAdmin {
        registeredRequesters[requester] = true;
    }

    function deregisterRequester(address requester) external onlyAdmin {
        registeredRequesters[requester] = false;
    }
    
    function attestAttribute(
        address owner,
        DataType scope,
        bytes32 claimHash,
        uint256 validityDays
    ) external onlyAttestor{
        require(identities[owner].exists, "user not registered");
        uint256 expiry = block.timestamp + (validityDays * 1 days);
        attestations[owner][scope] = Attestation(claimHash, expiry);
        emit Attested(owner, scope, msg.sender, claimHash, expiry);
    }

    
}