pragma solidity 0.5.16;

interface IVaultMetaRegistry {
    function getMetaProvider(address vault_address) external view returns (address);
}