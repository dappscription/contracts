// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "src/interfaces/IRegistry.sol";
import "forge-std/Test.sol";
import "src/core/Registry.sol";

import {Utilities} from "../utils/Utilities.sol";
import {Fixture} from "../shared/Fixture.t.sol";

contract TestContract is Fixture {
    // Registry registry;

    Utilities internal utils;
    address payable[] internal users;

    uint128 price = 100e6;
    uint40 period = 90 days;

    function setUp() public {
    }

    function testSubscribe() public {
        uint128 planId = registry.createPlan(address(usdc), alice, period, price, false);
        usdc.mint(babe, price);

        vm.startPrank(babe);
        usdc.approve(address(registry), price);
        uint256 subId = registry.subscribe(planId, true);
        vm.stopPrank();

        assertEq(registry.ownerOf(subId), babe);
        (bool hasSub, uint256 _subId) = registry.hasValidSubscription(planId, babe);
        assertTrue(hasSub);
        assertEq(_subId, subId);

        // assert transfer has been made
        assertEq(usdc.balanceOf(babe), 0);
        assertEq(usdc.balanceOf(alice), price);
    }

    function testUpdateSubscription() public {
        uint128 planId = registry.createPlan(address(usdc), alice, period, price, false);
        usdc.mint(babe, price);

        vm.startPrank(babe);
        usdc.approve(address(registry), price);
        uint256 subId = registry.subscribe(planId, true);
        (,,,bool allowAutoRenew) = registry.subs(subId);
        assertTrue(allowAutoRenew);
        
        registry.updateSubscription(subId, false);
        (,,,allowAutoRenew) = registry.subs(subId);
        assertTrue(!allowAutoRenew);
        vm.stopPrank();

        // test cannot call updateSubscription with non-owner
        vm.expectRevert(Registry.NotAuthorized.selector);
        registry.updateSubscription(subId, true);
    }

    function testIsValidSubscriptionAfterTransfer() public {
        uint128 planId = registry.createPlan(address(usdc), alice, period, price, false);
        
        usdc.mint(babe, price);

        vm.startPrank(babe);
        usdc.approve(address(registry), price);
        uint256 subId = registry.subscribe(planId, true);
        registry.transferFrom(babe, bob, subId);
        vm.stopPrank();

        assertEq(registry.ownerOf(subId), bob);
        (bool babeHasSub, ) = registry.hasValidSubscription(planId, babe);
        assertTrue(!babeHasSub);
        (bool bobHasSub, ) = registry.hasValidSubscription(planId, bob);
        assertTrue(bobHasSub);
    }

    // test that we can rebind a nft ownership after owning duplicated subscription plans
    function testRebind() public {
        uint128 planId = registry.createPlan(address(usdc), alice, period, price, false);
        
        usdc.mint(babe, price * 2);

        vm.startPrank(babe);
        usdc.approve(address(registry), price * 2);
        // make 2 subscription and transfer all to bob
        for (uint i = 0; i < 2; i++) {
            uint256 subId = registry.subscribe(planId, true);
            registry.transferFrom(babe, bob, subId);
        }
        vm.stopPrank();

        // transfer first sub nft back to babe
        vm.startPrank(bob);
        registry.transferFrom(bob, babe, 1);

        (bool babeHasSub, ) = registry.hasValidSubscription(planId, babe);
        assertTrue(babeHasSub);

        // bob will loss his record of hasValidSubscription because of duplicate holding.
        (bool bobHasSub, ) = registry.hasValidSubscription(planId, bob);
        assertTrue(!bobHasSub);

        vm.expectRevert(Registry.IllegalRebind.selector);
        registry.rebind(1, bob);

        // bob can rebind his ownership of the 2nd sub nft.
        registry.rebind(2, bob);
        (bobHasSub, ) = registry.hasValidSubscription(planId, bob);
        assertTrue(bobHasSub);


        vm.stopPrank();
    }

    // test that we can extend our subscription before expires
    function testRenewExtendable() public {
        bool extendable = true;
        uint128 planId = registry.createPlan(address(usdc), alice, period, price, extendable);
        // mint 2x price because we want to renew
        usdc.mint(babe, price * 2);

        vm.startPrank(babe);
        usdc.approve(address(registry), price * 2);
        uint256 subId = registry.subscribe(planId, true);
        (,,uint256 validUntilBefore,) = registry.subs(subId);

        registry.renew(subId);
        (,,uint256 validUntilAfter,) = registry.subs(subId);
        assertEq(validUntilAfter - validUntilBefore, period);
        vm.stopPrank();
    }

    // test that we can extend our subscription after expires
    function testRenewNotExtendable() public {
        bool extendable = false;
        uint128 planId = registry.createPlan(address(usdc), alice, period, price, extendable);
        // mint 2x price because we want to renew
        usdc.mint(babe, price * 2);

        vm.startPrank(babe);
        usdc.approve(address(registry), price * 2);
        uint256 subId = registry.subscribe(planId, true);
        (,,uint256 deadline,) = registry.subs(subId);

        vm.expectRevert(Registry.SubscriptionNotExpired.selector);
        registry.renew(subId);
        
        // set time to expiration
        vm.warp(deadline);
        registry.renew(subId);
        (,,uint256 newDeadline,) = registry.subs(subId);
        assertEq(newDeadline, block.timestamp + period);
        vm.stopPrank();
    }

    function testCannotSubscribeNonExistantPlan(uint128 id) public {
        vm.expectRevert(Registry.ProjectDoesNotExist.selector);
        registry.subscribe(id, true);
    }
}
