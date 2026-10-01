// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.34;

import {Token} from "./Token.sol";
import {Test} from "forge-std/Test.sol";

contract TokenTest is Test {
    Token token;

    function setUp() public {
        token = new Token();
    }

    function test_Mint_IncreasesBalance() public {
        address alice = address(0xA11CE);

        token.mint(alice, 10);

        assertEq(token.balanceOf(alice), 10);
    }

    function test_Mint_RevertsIfNotOwner() public {
        address notOwner = address(0xBEEF);

        vm.prank(notOwner);
        vm.expectRevert("Not authorized");
        token.mint(notOwner, 10);
    }

    function test_TransferOwnership_RevertsIfNotOwner() public {
        address notOwner = address(0xBEEF);

        vm.prank(notOwner);
        vm.expectRevert("Not authorized");
        token.transferOwnership(notOwner);
    }

    function test_TransferOwnership_OldOwnerLosesMintRights() public {
        address newOwner = address(0xC0FFEE);

        token.transferOwnership(newOwner);

        vm.expectRevert("Not authorized");
        token.mint(address(0xA11CE), 10);
    }
}
