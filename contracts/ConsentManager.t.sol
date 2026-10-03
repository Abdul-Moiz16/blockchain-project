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

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        identityRegistry = new IdentityRegistry();
        token = new Token();
        consentManager = new ConsentManager(address(identityRegistry), address(token));

        token.transferOwnership(address(consentManager));

        // createConsent now requires the owner to be registered and the requester
        // to be on the admin-approved allow-list — do both once here.
        vm.prank(alice);
        identityRegistry.registerUser(keccak256("alice-data"), "ref-1");
        identityRegistry.registerRequester(bob);
    }


    // tests if the mints get given to the account. so check if the coin is actually minted after giving consent
    // also tests if the permission works for full statement
    function test_CreateConsent_MintsTokenAndGrantsAccess() public {
        vm.prank(alice);
        consentManager.createConsent(bob, DataType.FULL_STATEMENT, 2 days, "credit");

        assertEq(token.balanceOf(alice), 1);

        bool hasAccess = consentManager.checkPermission(bob, alice, DataType.FULL_STATEMENT);
        assertTrue(hasAccess);
    }



    // tests if it fails if the permission level is too low, so only permitted to look at credit tier but tries to look at the full statement
    function test_CheckPermission_ReturnsFalseIfLevelTooLow() public {
        vm.prank(alice);
        consentManager.createConsent(bob, DataType.CREDIT_TIER_ONLY, 2 days, "Credit check");

        bool hasAccess = consentManager.checkPermission(bob, alice, DataType.FULL_STATEMENT);
        assertFalse(hasAccess);
    }


    // checks if for the income band if exact access and lower access works. basically just edge testing at this point
    function test_CheckPermission_ReturnsTrueIfLevelSufficient() public {
        vm.prank(alice);
        consentManager.createConsent(bob, DataType.INCOME_BAND, 2 days, "check income");

        bool hasExactAccess = consentManager.checkPermission(bob, alice, DataType.INCOME_BAND);
        assertTrue(hasExactAccess);

        bool hasLowerAccess = consentManager.checkPermission(bob, alice, DataType.CREDIT_TIER_ONLY);
        assertTrue(hasLowerAccess);
    }

    // this checks if the revokeconsent works. so you give consent and then you take it away, it its actually taken away
    function test_RevokeConsent_RemovesAccess() public {
        vm.prank(alice);
        consentManager.createConsent(bob, DataType.FULL_STATEMENT, 2 days, "access");

        vm.prank(alice);
        consentManager.revokeConsent(bob);

        bool hasAccess = consentManager.checkPermission(bob, alice, DataType.FULL_STATEMENT);
        assertFalse(hasAccess);
    }

    // checks if the expiry works. so give access, warp till after the acces expires and check if the access is indeed gone.
    function test_CheckPermission_ReturnsFalseIfExpired() public {
        vm.prank(alice);
        consentManager.createConsent(bob, DataType.FULL_STATEMENT, 2 days, "Mortgage underwriting");

        vm.warp(block.timestamp + 2 days + 1);

        bool hasAccess = consentManager.checkPermission(bob, alice, DataType.FULL_STATEMENT);
        assertFalse(hasAccess);
    }

    // createConsent must reject an owner who never registered their identity
    function test_CreateConsent_RevertsIfOwnerNotRegistered() public {
        address notRegistered = address(0xBAD);

        vm.prank(notRegistered);
        vm.expectRevert("owner not registered");
        consentManager.createConsent(bob, DataType.FULL_STATEMENT, 2 days, "credit");
    }

    // createConsent must reject a requester the admin never approved
    function test_CreateConsent_RevertsIfRequesterNotRegistered() public {
        address notARequester = address(0xC0FFEE);

        vm.prank(alice);
        vm.expectRevert("requester not registered");
        consentManager.createConsent(notARequester, DataType.FULL_STATEMENT, 2 days, "credit");
    }

    // createConsent must reject a duration outside the 1-365 day range
    function test_CreateConsent_RevertsIfDurationOutOfRange() public {
        vm.prank(alice);
        vm.expectRevert("duration out of range");
        consentManager.createConsent(bob, DataType.FULL_STATEMENT, 1500, "credit");

        vm.prank(alice);
        vm.expectRevert("duration out of range");
        consentManager.createConsent(bob, DataType.FULL_STATEMENT, 366 days, "credit");
    }

    // a requester removed by admin must lose access even if consent still holds
    function test_CheckPermission_ReturnsFalseIfRequesterDeregistered() public {
        vm.prank(alice);
        consentManager.createConsent(bob, DataType.FULL_STATEMENT, 2 days, "credit");
        assertTrue(consentManager.checkPermission(bob, alice, DataType.FULL_STATEMENT));

        identityRegistry.deregisterRequester(bob);

        assertFalse(consentManager.checkPermission(bob, alice, DataType.FULL_STATEMENT));
    }
}
