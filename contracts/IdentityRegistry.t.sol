// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;

import {IdentityRegistry} from "./IdentityRegistry.sol";
import {DataType} from "./DataTypes.sol";
import {Test} from "forge-std/Test.sol";



contract IdentityRegistryTest is Test {
    IdentityRegistry registry;

    function setUp() public {
        registry = new IdentityRegistry();
    }

    function test_RegisterUser_StoresIdentity() public {
        address alice = address(0xA11CE);
        bytes32 hash = keccak256("alice-data");

        vm.prank(alice);
        registry.registerUser(hash, "ref-1");

        (bool exists, bytes32 storedHash, ) = registry.identities(alice);
        assertTrue(exists);
        assertEq(storedHash, hash);
    }

    function test_RegisterAttestor_RevertsIfNotAdmin() public {
        address notAdmin = address(0xBEEF);

        vm.prank(notAdmin);
        vm.expectRevert("not admin");
        registry.registerAttestor(notAdmin);
    }

    function test_AttestAttribute_RevertsIfNotAttestor() public {
        address alice = address(0xA11CE);
        address notAttestor = address(0xBEEF);

        vm.prank(alice);
        registry.registerUser(keccak256("alice-data"), "ref-1");

        vm.prank(notAttestor);
        vm.expectRevert("not attestor");
        registry.attestAttribute(alice, DataType.CREDIT_TIER_ONLY, keccak256("A"), 30);
    }

    function test_AttestAttribute_RevertsIfUserNotRegistered() public {
        address bank = address(0xBEEF01);
        address notRegistered = address(0xDEAD);

        registry.registerAttestor(bank);

        vm.prank(bank);
        vm.expectRevert("user not registered");
        registry.attestAttribute(notRegistered, DataType.CREDIT_TIER_ONLY, keccak256("A"), 30);
    }

    function test_AttestAttribute_DoesNotOverwriteOtherScope() public {
        address alice = address(0xA11CE);
        address bank = address(0xBEEF01);

        vm.prank(alice);
        registry.registerUser(keccak256("alice-data"), "ref-1");

        registry.registerAttestor(bank);

        vm.prank(bank);
        registry.attestAttribute(alice, DataType.CREDIT_TIER_ONLY, keccak256("A"), 180);

        vm.prank(bank);
        registry.attestAttribute(alice, DataType.INCOME_BAND, keccak256("40-60k"), 90);

        (bytes32 tierHash, ) = registry.attestations(alice, DataType.CREDIT_TIER_ONLY);
        (bytes32 incomeHash, ) = registry.attestations(alice, DataType.INCOME_BAND);

        assertEq(tierHash, keccak256("A"));
        assertEq(incomeHash, keccak256("40-60k"));
    }

                
}
