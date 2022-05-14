// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "src/core/Registry.sol";

import {Utilities} from "../utils/Utilities.sol";
import {Fixture} from "../shared/Fixture.t.sol";

contract TestTransferSub is Fixture {

    uint128 planId;
    uint256 subId;

    function setUp() public {
        planId = registry.createPlan(
            address(usdc),
            alice,
            period,
            price,
            false
        );
        usdc.mint(address(this), price * 2);
        usdc.approve(address(registry), price * 2);

        subId = registry.subscribe(planId, true);
    }

    function testSubTransferable() public {
        // act
        registry.transferFrom(address(this), bob, subId);
        // assert
        assertEq(registry.ownerOf(subId), bob);
    }

    function testSubTransferChangeIsValidSubOutput() public {
        // act
        registry.transferFrom(address(this), bob, subId);
        // assert
        (bool hasSub, ) = registry.hasValidSubscription(planId, address(this));
        assertTrue(!hasSub);
        (bool bobHasSub, ) = registry.hasValidSubscription(planId, bob);
        assertTrue(bobHasSub);
    }

    function testCannotOwnTwoSub() public {
        // arrange
        registry.transferFrom(address(this), bob, subId);
        uint256 sub2Id = registry.subscribe(planId, true);

        // act
        vm.expectRevert(Registry.AlreadySubscribed.selector);
        registry.transferFrom(address(this), bob, sub2Id);
    }
}
