// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "src/interfaces/IRegistry.sol";
import "forge-std/Test.sol";
import "src/core/Registry.sol";

import {Utilities} from "../utils/Utilities.sol";
import {Fixture} from "../shared/Fixture.t.sol";

contract TestCreate is Fixture {

    event PlanCreated(uint128 planId, address owner, address token, uint40 period, uint128 price);

    uint128 price = 100e6;
    uint40 period = 90 days;
    bool extendable = true;

    function testCreateIncreaseId() public {        
        uint128 expectedId = registry.nextPlanId();
        uint128 planId = registry.createPlan(address(usdc), alice, period, price, extendable);
        assertEq(expectedId, planId);
    }

    function testCreateEmitEvent() public {
        uint128 id = registry.nextPlanId();
        vm.expectEmit(false, false, false, true);
        emit PlanCreated(id, address(this), address(usdc), period, price);
        registry.createPlan(address(usdc), alice, period, price, extendable);
    }

    function testCreateUpdateState() public {        
        uint128 planId = registry.createPlan(address(usdc), alice, period, price, extendable);

        (address _owner, address _recipiet, address token, uint40 _period, uint40 _lastModifiedTimestamp, uint128 _price, bool _extendable) = registry.plans(planId);
        assertEq(_owner, address(this));
        assertEq(_recipiet, alice);
        assertEq(token, address(usdc));
        assertEq(_period, period);
        assertEq(_lastModifiedTimestamp, block.timestamp);
        assertEq(_price, price);
        assertTrue(extendable == _extendable);
    }

    
}
