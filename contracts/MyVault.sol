
// contracts/MyVaultNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.5.5;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";

contract VaultNFT is ERC721Full {
        
    address admin;
    
    constructor() public ERC721Full("miMATIC Vault", "MMTV") {
        admin = msg.sender;
    }
    
    function setAdmin(address _admin) public {
        require(admin==msg.sender);
        admin=_admin;
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        revert("transfer: disabled");
    }
    
    function burn(uint256 tokenId) public {
        require(
            msg.sender == admin,
            "Token: account does not have burn role"
        );
        _burn(tokenId);
    }
    
    function mint(address to, uint256 tokenId) public {
        require(
            msg.sender == admin,
            "Token: account does not have minter role"
        );
        _mint(to, tokenId);
    }
}