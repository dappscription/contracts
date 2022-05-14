// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "src/core/Registry.sol";

import {Utilities} from "../utils/Utilities.sol";
import {Fixture} from "../shared/Fixture.t.sol";

contract TestRenewNonExtendableSub is Fixture {

    uint128 price = 100e6;
    uint40 period = 90 days;
    bool extendable = false;

    uint128 planId;
    uint256 subId;
    
    function setUp() public {
        planId = registry.createPlan(
            address(usdc),
            alice,
            period,
            price,
            extendable
        );

        usdc.mint(address(this), price * 2);
        usdc.approve(address(registry), price * 2);

        subId = registry.subscribe(planId, true);
    }

    function testCannotRenewBeforeDeadline() public {
        vm.expectRevert(Registry.SubscriptionNotExpired.selector);
        registry.renew(subId);
    }


    function testCanRenewAfterExpiry() public {
        // arrange
        (,,uint256 deadline,) = registry.subs(subId);
        uint256 delay = 30 * 1 days;
        vm.warp(deadline + delay);

        // act
        registry.renew(subId);

        // assert
        (,,uint256 newDeadline,) = registry.subs(subId);
        assertEq(period + block.timestamp, newDeadline);
    }
}
