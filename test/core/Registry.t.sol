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

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);

        registry = new Registry();
        usdc = new MintableERC20();
    }

    function testCreatePlanAndSubscribe() public {
        address recipient = users[1];
        uint128 price = 100e6;
        uint40 period = 90 days;
        uint128 expectedId = registry.nextPlanId();

        uint128 id = registry.createPlan(address(usdc), recipient, period, price);
        assertEq(expectedId, id);

        (address _owner, address _recipiet, address token, uint40 _period, uint40 _lastModifiedTimestamp, uint128 _price) = registry.plans(id);
        assertEq(_owner, address(this));
        assertEq(_recipiet, recipient);
        assertEq(address(usdc), token);
        assertEq(_period, period);
        assertEq(_lastModifiedTimestamp, block.timestamp);
        assertEq(_price, price);

        // subscribe to plan
        address payable alice = users[2];
        usdc.mint(alice, price);
        vm.startPrank(alice);
        usdc.approve(address(registry), price);
        
        uint256 nftId = registry.subscribe(id, true);
        assertEq(registry.ownerOf(nftId), alice);

        vm.stopPrank();
    }

    function testCannotSubscribeNonExistantPlan() internal {
        vm.expectRevert(Registry.ProjectDoesNotExist.selector);
        registry.subscribe(0, true);
    }
}
