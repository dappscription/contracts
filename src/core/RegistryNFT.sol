// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";

contract RegistryNFT is ERC721{

    constructor() ERC721("Dappscription Receipt", "Sub") {}
    
    function tokenURI(uint256) public pure override returns (string memory) {
      return "";
    }

}
