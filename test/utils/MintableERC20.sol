// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";

contract MintableERC20 is ERC20 {
  constructor() ERC20("USDC", "USDC", 6) {}

  function mint(address _to, uint256 _amount) external {
    _mint(_to, _amount);
  }
}