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

        uint128 id = registry.createPlan(address(usdc), recipient, period, price);
        assertEq(expectedId, id);

        (address _owner, address _recipiet, address token, uint40 _period, uint40 _lastModifiedTimestamp, uint128 _price) = registry.plans(id);
        assertEq(_owner, address(this));
        assertEq(_recipiet, recipient);
        assertEq(token, address(usdc));
        assertEq(_period, period);
        assertEq(_lastModifiedTimestamp, block.timestamp);
        assertEq(_price, price);
    }

    function testSubscribe() public {
        address recipient = users[1];
        uint128 id = registry.createPlan(address(usdc), recipient, period, price);
        address payable alice = users[2];
        usdc.mint(alice, price);

        vm.startPrank(alice);
        usdc.approve(address(registry), price);
        uint256 nftId = registry.subscribe(id, true);
        vm.stopPrank();

        assertEq(registry.ownerOf(nftId), alice);

        // assert transfer has been made
        assertEq(usdc.balanceOf(alice), 0);
        assertEq(usdc.balanceOf(recipient), price);
    }

    function testCannotSubscribeNonExistantPlan(uint128 id) public {
        vm.expectRevert(Registry.ProjectDoesNotExist.selector);
        registry.subscribe(id, true);
    }
}
