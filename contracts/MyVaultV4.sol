// contracts/MyVaultNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";

contract VaultNFTv4 is ERC721Full {

    string public uri;

    constructor(string memory name, string memory symbol, string memory _uri)
    public
    ERC721Full(name, symbol)
    {
        uri = _uri;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId));

        return uri;
    }
}
