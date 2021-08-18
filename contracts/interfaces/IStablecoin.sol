pragma solidity 0.5.5;

interface IStablecoin {
	
	function getDebtCeiling() external view returns (uint256);

    function getClosingFee() external view returns (uint256);

    function getOpeningFee() external view returns (uint256);

    function getTokenPriceSource() external view returns (uint256);

    function getEthPriceSource() external view returns (uint256);

    function createVault() external returns (uint256);

    function destroyVault(uint256 vaultID) external;

    function transferVault(uint256 vaultID, address to) external;

    function depositCollateral(uint256 vaultID) external payable;

    function withdrawCollateral(uint256 vaultID, uint256 amount) external;

    function borrowToken(uint256 vaultID, uint256 amount) external;

    function payBackToken(uint256 vaultID, uint256 amount) external;

    function buyRiskyVault(uint256 vaultID) external;
}