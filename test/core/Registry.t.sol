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
}
