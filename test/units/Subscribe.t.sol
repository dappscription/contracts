// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "src/core/Registry.sol";

import {Utilities} from "../utils/Utilities.sol";
import {Fixture} from "../shared/Fixture.t.sol";

contract TestSubscribe is Fixture {

    event PlanCreated(uint128 planId, address owner, address token, uint40 period, uint128 price);

    uint128 price = 100e6;
    uint40 period = 90 days;
    bool extendable = true;

    uint128 planId;

    function setUp() public {
        planId = registry.createPlan(address(usdc), alice, period, price, false);
        usdc.mint(address(this), price);
        usdc.approve(address(registry), price);
    }

    function testSubscribeMintNFT() public {
        // act
        uint256 subId = registry.subscribe(planId, true);
        // assert
        assertEq(registry.ownerOf(subId), address(this));
    }

    function testSubscribeValid() public {
        // act
        uint256 subId = registry.subscribe(planId, true);

        // assert
        (bool hasSub, uint256 _subId) = registry.hasValidSubscription(planId, address(this));
        assertTrue(hasSub);
        assertEq(_subId, subId);
    }

    function testSubscribePayToken() public {
        // act
        registry.subscribe(planId, true);
        // assert
        assertEq(usdc.balanceOf(address(this)), 0);
        assertEq(usdc.balanceOf(alice), price);
    }

    function testCannotSubscribeNonExistantPlan() public {
        vm.expectRevert(Registry.ProjectDoesNotExist.selector);
        registry.subscribe(planId + 1, true);
    }
}
