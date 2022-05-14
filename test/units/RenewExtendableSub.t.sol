// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "src/core/Registry.sol";

import {Fixture} from "../shared/Fixture.t.sol";

contract TestRenewExtendableSub is Fixture {
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

    function testCanRenewBeforeDeadline() public {
        // arrange
        (,,uint256 validUntilBefore,) = registry.subs(subId);

        // act
        registry.renew(subId);

        // assert
        (,,uint256 validUntilAfter,) = registry.subs(subId);
        assertEq(validUntilAfter - validUntilBefore, period);
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
