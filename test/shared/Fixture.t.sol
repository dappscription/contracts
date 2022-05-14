// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../mocks/MockERC20.sol";

import "src/core/Registry.sol";

abstract contract Fixture is Test {
    Registry internal registry;
    
    MockERC20 internal usdc;

    address internal alice;
    address internal babe;
    address internal bob;

    // defaut plan
    uint128 price = 100e6;
    uint40 period = 90 days;
    bool extendable = true;
    
    constructor() {
        usdc = new MockERC20("USDC", "USDC", 6);

        registry = new Registry();

        babe = address(0xbabe);
        vm.label(babe, "Babe");

        bob = address(0xb0b);
        vm.label(bob, "Bob");

        alice = address(0xaaaa);
        vm.label(alice, "Alice");

        // make sure timestamp is not 0
        vm.warp(0xffff);
    }
}
