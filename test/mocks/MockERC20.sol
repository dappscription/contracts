// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
  constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol, decimals) {}

  function mint(address _to, uint256 _amount) external {
    _mint(_to, _amount);
  }
}