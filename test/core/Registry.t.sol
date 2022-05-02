// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "src/interfaces/IRegistry.sol";

import "forge-std/Test.sol";
import "src/core/Registry.sol";

contract TestContract is Test {
    Registry registry;

    function setUp() public {
        registry = new Registry();
    }

    function testCreatePlan() public {
        address token = address(5);
        address recipient = address(980);
        uint128 price = 100e6;
        uint40 period = 90 days;
        uint128 expectedId = registry.nextPlanId();

        uint128 id = registry.createPlan(token, recipient, period, price);
        assertEq(expectedId, id);

        (address _owner, address _recipiet, address paymentToken, uint40 _period, uint40 _lastModifiedTimestamp, uint128 _price) = registry.plans(id);
        assertEq(_owner, address(this));
        assertEq(_recipiet, recipient);
        assertEq(paymentToken, token);
        assertEq(_period, period);
        assertEq(_lastModifiedTimestamp, block.timestamp);
        assertEq(_price, price);
    }
}
