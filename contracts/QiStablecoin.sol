pragma solidity 0.5.5;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./Stablecoin.sol";

contract QiStablecoin is Stablecoin, Ownable {
    constructor(
        address ethPriceSourceAddress,
        uint256 minimumCollateralPercentage,
        string memory name,
        string memory symbol,
        address vaultAddress
    ) Stablecoin(
        ethPriceSourceAddress,
        minimumCollateralPercentage,
        name,
        symbol,
        vaultAddress
    ) public {
        treasury=0;
    }

    function mint(address account, uint256 amount) external onlyOwner() {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner() {
        _burn(account, amount);
    }

    function changeEthPriceSource(address ethPriceSourceAddress) external onlyOwner() {
        ethPriceSource = PriceSource(ethPriceSourceAddress);
    }

    function setTokenPeg(uint256 _tokenPeg) external onlyOwner() {
        tokenPeg = _tokenPeg;
    }

    function setStabilityPool(address _pool) external onlyOwner() {
        stabilityPool = _pool;
    }

    function setDebtCeiling(uint256 amount) external onlyOwner() {
        require(totalSupply()<=amount, "setCeiling: Must be over the amount of outstanding debt.");
        debtCeiling = amount;
    }

    function setClosingFee(uint256 amount) external onlyOwner() {
        closingFee = amount;
    }

    function setOpeningFee(uint256 amount) external onlyOwner() {
        openingFee = amount;
    }

    function setTreasury(uint256 _treasury) external onlyOwner() {
        require(vaultExistence[_treasury], "Vault does not exist");
        treasury = _treasury;
    }
}