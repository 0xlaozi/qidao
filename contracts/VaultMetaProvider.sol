pragma solidity 0.5.16;

import "./interfaces/IVaultMetaProvider.sol";

contract VaultMetaProvider {

    string public _tokenURI;

    constructor (string memory tokenURI) public {
        _tokenURI = tokenURI;
    }

    function getTokenURI(address vault_address, uint256 tokenId) public view returns (string memory) {
        return _tokenURI;
    }
}