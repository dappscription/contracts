// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";

contract FakeUSDC is ERC20 {
  constructor() ERC20("USDC", "USDC", 6) {}
}