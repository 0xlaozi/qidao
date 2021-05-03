
// contracts/IMyVaultNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.5.5;

interface IMyVault {
    function burn(uint256 tokenId) external;

    function mint(address to, uint256 tokenId) external;
}