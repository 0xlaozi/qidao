
// contracts/MyVaultNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.5.5;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";

contract VaultNFTv2 is ERC721Full {
            
    constructor(string memory name, string memory symbol) public ERC721Full(name, symbol) {}

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        revert("transfer: disabled");
    }
}