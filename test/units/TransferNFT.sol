// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "src/core/Registry.sol";

import {Utilities} from "../utils/Utilities.sol";
import {Fixture} from "../shared/Fixture.t.sol";

contract TestUpdateSubscription is Fixture {

    uint128 price = 100e6;
    uint40 period = 90 days;
    bool extendable = true;

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
        usdc.mint(address(this), price);
        usdc.approve(address(registry), price);

        subId = registry.subscribe(planId, true);
    }

    function testSubTransferable() public {
        registry.transferFrom(address(this), bob, subId);

        assertEq(registry.ownerOf(subId), bob);
    }

    function testSubTransferChangeIsValidSubOutput() public {
        // act
        registry.transferFrom(address(this), bob, subId);

        (bool hasSub, ) = registry.hasValidSubscription(planId, address(this));
        assertTrue(!hasSub);
        (bool bobHasSub, ) = registry.hasValidSubscription(planId, bob);
        assertTrue(bobHasSub);
    }
}
