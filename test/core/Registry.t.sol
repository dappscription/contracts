// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "src/interfaces/IRegistry.sol";
import "forge-std/Test.sol";
import "src/core/Registry.sol";

import {MintableERC20} from "../utils/MintableERC20.sol";
import {Utilities} from "../utils/Utilities.sol";


contract TestContract is Test {
    Registry registry;
    MintableERC20 usdc;

    Utilities internal utils;
    address payable[] internal users;

    uint128 price = 100e6;
    uint40 period = 90 days;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);

        registry = new Registry();
        usdc = new MintableERC20();
    }

    function testCreate() public {
        address recipient = users[1];
        
        uint128 expectedId = registry.nextPlanId();
        bool extendable = true;
        uint128 planId = registry.createPlan(address(usdc), recipient, period, price, extendable);
        assertEq(expectedId, planId);

        (address _owner, address _recipiet, address token, uint40 _period, uint40 _lastModifiedTimestamp, uint128 _price, bool _extendable) = registry.plans(planId);
        assertEq(_owner, address(this));
        assertEq(_recipiet, recipient);
        assertEq(token, address(usdc));
        assertEq(_period, period);
        assertEq(_lastModifiedTimestamp, block.timestamp);
        assertEq(_price, price);
        assertTrue(extendable == _extendable);
    }

    function testSubscribe() public {
        address recipient = users[1];
        uint128 planId = registry.createPlan(address(usdc), recipient, period, price, false);
        address payable alice = users[2];
        usdc.mint(alice, price);

        vm.startPrank(alice);
        usdc.approve(address(registry), price);
        uint256 subId = registry.subscribe(planId, true);
        vm.stopPrank();

        assertEq(registry.ownerOf(subId), alice);
        (bool hasSub, uint256 _subId) = registry.hasValidSubscription(planId, alice);
        assertTrue(hasSub);
        assertEq(_subId, subId);

        // assert transfer has been made
        assertEq(usdc.balanceOf(alice), 0);
        assertEq(usdc.balanceOf(recipient), price);
    }

    function testUpdateSubscription() public {
        address recipient = users[1];
        uint128 planId = registry.createPlan(address(usdc), recipient, period, price, false);
        address payable alice = users[2];
        usdc.mint(alice, price);

        vm.startPrank(alice);
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
        address recipient = users[1];
        address payable alice = users[2];
        address payable bob = users[3];

        uint128 planId = registry.createPlan(address(usdc), recipient, period, price, false);
        
        usdc.mint(alice, price);

        vm.startPrank(alice);
        usdc.approve(address(registry), price);
        uint256 subId = registry.subscribe(planId, true);
        registry.transferFrom(alice, bob, subId);
        vm.stopPrank();

        assertEq(registry.ownerOf(subId), bob);
        (bool aliceHasSub, ) = registry.hasValidSubscription(planId, alice);
        assertTrue(!aliceHasSub);
        (bool bobHasSub, ) = registry.hasValidSubscription(planId, bob);
        assertTrue(bobHasSub);
    }

    // test that we can rebind a nft ownership after owning duplicated subscription plans
    function testRebind() public {
        address recipient = users[1];
        address payable alice = users[2];
        address payable bob = users[3];
        uint128 planId = registry.createPlan(address(usdc), recipient, period, price, false);
        
        usdc.mint(alice, price * 2);

        vm.startPrank(alice);
        usdc.approve(address(registry), price * 2);
        // make 2 subscription and transfer all to bob
        for (uint i = 0; i < 2; i++) {
            uint256 subId = registry.subscribe(planId, true);
            registry.transferFrom(alice, bob, subId);
        }
        vm.stopPrank();

        // transfer first sub nft back to alice
        vm.startPrank(bob);
        registry.transferFrom(bob, alice, 1);

        (bool aliceHasSub, ) = registry.hasValidSubscription(planId, alice);
        assertTrue(aliceHasSub);

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
        address recipient = users[1];
        bool extendable = true;
        uint128 planId = registry.createPlan(address(usdc), recipient, period, price, extendable);
        address payable alice = users[2];
        // mint 2x price because we want to renew
        usdc.mint(alice, price * 2);

        vm.startPrank(alice);
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
        address recipient = users[1];
        bool extendable = false;
        uint128 planId = registry.createPlan(address(usdc), recipient, period, price, extendable);
        address payable alice = users[2];
        // mint 2x price because we want to renew
        usdc.mint(alice, price * 2);

        vm.startPrank(alice);
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
