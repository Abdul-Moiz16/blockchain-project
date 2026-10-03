// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;

import {Test} from "forge-std/Test.sol";
import {DataSharing} from "./Datasharing.sol";
import {ConsentManager} from "./ConsentManager.sol";
import {Token} from "./Token.sol";
import {IdentityRegistry} from "./IdentityRegistry.sol";
import {DataType} from "./DataTypes.sol";

contract DataSharingTest is Test {
    DataSharing dataSharing;
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
        dataSharing = new DataSharing(address(consentManager));


        //making alice registered user and bob admin-approved requester
        vm.prank(alice);
        identityRegistry.registerUser(keccak256("alice-data"), "ref-1");
        identityRegistry.registerRequester(bob);
    }


    //helper for asserting log entries
    function assertLogEntry(uint256 index, DataType level, bool result, bytes32 ticket) internal {
        (address requester, address user, DataType loggedLevel, , bool loggedResult, bytes32 loggedTicket) = dataSharing.accessLog(index);
        assertEq(requester, bob);
        assertEq(user, alice);
        assertEq(uint256(loggedLevel), uint256(level));
        assertEq(loggedResult, result);
        assertEq(loggedTicket, ticket);
    }


    //successful access granted if user and data type match a consent from alice
    //request is written into log
    function test_RequestAccess_ConstentedDataSucceedsAndLogged() public {
        vm.prank(alice);
        consentManager.createConsent(bob, DataType.INCOME_BAND, 2 days, "credit check");

        vm.prank(bob);
        bytes32 ticket = dataSharing.requestAccess(alice, DataType.INCOME_BAND);

        //ticket is not a failed requested (all 0)
        assertTrue(ticket != bytes32(0));

        //log the data and check if log entry says the right stuff
        assertLogEntry(0, DataType.INCOME_BAND, true, ticket);
    }

    //failed access is denied but still logged into log (not dropped)
    function test_RequestAccess_AccessDeniedAndLogged() public {
        vm.prank(alice);
        consentManager.createConsent(bob, DataType.CREDIT_TIER_ONLY, 2 days, "credit check");

        vm.prank(bob);
        bytes32 ticket = dataSharing.requestAccess(alice, DataType.FULL_STATEMENT);

        //ticket is an all-0 num => failed
        assertEq(ticket, bytes32(0));

        //check if log says what it should
        assertLogEntry(0, DataType.FULL_STATEMENT, false, bytes32(0));
    }

    //if bob requests something alice didn't consent, it fails
    function test_DenyUnconsented() public{
        vm.prank(bob);
        bytes32 ticket = dataSharing.requestAccess(alice, DataType.CREDIT_TIER_ONLY);

        assertEq(ticket, bytes32(0));

        assertLogEntry(0, DataType.CREDIT_TIER_ONLY, false, bytes32(0));
    }

    //if admin removes previously approved requester, request fails
    function test_RequestAccess_DeniedIfRequesterDeregistered() public {
        vm.prank(alice);
        consentManager.createConsent(bob, DataType.FULL_STATEMENT, 2 days, "credit check");

        identityRegistry.deregisterRequester(bob);

        vm.prank(bob);
        bytes32 ticket = dataSharing.requestAccess(alice, DataType.FULL_STATEMENT);

        assertEq(ticket, bytes32(0));

        assertLogEntry(0, DataType.FULL_STATEMENT, false, bytes32(0));
    }





}



