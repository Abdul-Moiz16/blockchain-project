// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;

import {Test} from "forge-std/Test.sol";
import {ConsentManager} from "./ConsentManager.sol";
import {Token} from "./Token.sol";
import {IdentityRegistry} from "./IdentityRegistry.sol";
import {DataType} from "./DataTypes.sol";

contract ConsentManagerTest is Test {
    ConsentManager consentManager;
    Token token;
    IdentityRegistry identityRegistry;

    function setUp() public {
        identityRegistry = new IdentityRegistry();
        token = new Token();
        consentManager = new ConsentManager(address(identityRegistry), address(token));
        
        token.transferOwnership(address(consentManager));
    }


    // tests if the mints get given to the account. so check if the coin is actually minted after giving consent
    // also tests if the permission works for full statement 
    function test_CreateConsent_MintsTokenAndGrantsAccess() public {
        address alice = address(0xA11CE);
        address bob = address(0xB0B);

        vm.prank(alice);
        consentManager.createConsent(bob, DataType.FULL_STATEMENT, 1500, "credit");

        assertEq(token.balanceOf(alice), 1);
        
        bool hasAccess = consentManager.checkPermission(bob, alice, DataType.FULL_STATEMENT);
        assertTrue(hasAccess);
    }



    // tests if it fails if the permission level is too low, so only permitted to look at credit tier but tries to look at the full statement
    function test_CheckPermission_ReturnsFalseIfLevelTooLow() public {
        address alice = address(0xA11CE);
        address bob = address(0xB0B);

        vm.prank(alice);
        consentManager.createConsent(bob, DataType.CREDIT_TIER_ONLY, 1500, "Credit check");

        bool hasAccess = consentManager.checkPermission(bob, alice, DataType.FULL_STATEMENT);
        assertFalse(hasAccess);
    }


    // checks if for the income band if exact access and lower access works. basically just edge testing at this point
    function test_CheckPermission_ReturnsTrueIfLevelSufficient() public {
        address alice = address(0xA11CE);
        address bob = address(0xB0B);

        vm.prank(alice);
        consentManager.createConsent(bob, DataType.INCOME_BAND, 1500, "check income");

        bool hasExactAccess = consentManager.checkPermission(bob, alice, DataType.INCOME_BAND);
        assertTrue(hasExactAccess);

        bool hasLowerAccess = consentManager.checkPermission(bob, alice, DataType.CREDIT_TIER_ONLY);
        assertTrue(hasLowerAccess);
    }

    // this checks if the revokeconsent works. so you give consent and then you take it away, it its actually taken away
    function test_RevokeConsent_RemovesAccess() public {
        address alice = address(0xA11CE);
        address bob = address(0xB0B);

        vm.prank(alice);
        consentManager.createConsent(bob, DataType.FULL_STATEMENT, 1500, "access");

        vm.prank(alice);
        consentManager.revokeConsent(bob);

        bool hasAccess = consentManager.checkPermission(bob, alice, DataType.FULL_STATEMENT);
        assertFalse(hasAccess);
    }

    // checks if the expiry works. so give access, warp till after the acces expires and check if the access is indeed gone.
    function test_CheckPermission_ReturnsFalseIfExpired() public {
        address alice = address(0xA11CE);
        address bob = address(0xB0B);

        vm.prank(alice);
        consentManager.createConsent(bob, DataType.FULL_STATEMENT, 1500, "Mortgage underwriting");

        vm.warp(block.timestamp + 1501);

        bool hasAccess = consentManager.checkPermission(bob, alice, DataType.FULL_STATEMENT);
        assertFalse(hasAccess);
    }
}