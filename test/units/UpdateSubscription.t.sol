// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "src/core/Registry.sol";

import {Utilities} from "../utils/Utilities.sol";
import {Fixture} from "../shared/Fixture.t.sol";

contract TestUpdateSubscription is Fixture {

    event PlanCreated(uint128 planId, address owner, address token, uint40 period, uint128 price);

    uint128 price = 100e6;
    uint40 period = 90 days;
    bool extendable = true;

    uint128 planId;
    uint256 subId;

    function setUp() public {
        planId = registry.createPlan(address(usdc), alice, period, price, false);
        usdc.mint(address(this), price);
        usdc.approve(address(registry), price);

        subId = registry.subscribe(planId, true);
    }

    function testUpdateSubChangeState() public {
        // act
        registry.updateSubscription(subId, false);

        // assert
        (,,,bool allowAutoRenew) = registry.subs(subId);
        assertTrue(!allowAutoRenew);
    }

    function testCannotUpdateNonExistingSub() public {
        vm.expectRevert("NOT_MINTED");
        registry.updateSubscription(subId + 1, true);
    }

    function testCannotUpdateSubByNonOwner() public {
        vm.prank(bob);
        // test cannot call updateSubscription with non-owner
        vm.expectRevert(Registry.NotAuthorized.selector);
        registry.updateSubscription(subId, true);
    }
}
