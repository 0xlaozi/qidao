
pragma solidity 0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./erc20Stablecoin-wbtc.sol";

contract erc20QiStablecoinwbtc is erc20Stablecoinwbtc, Ownable {

    constructor(
        address ethPriceSourceAddress,
        uint256 minimumCollateralPercentage,
        string memory name,
        string memory symbol,
        address _mai,
        address _collateral,
        address meta,
        string memory baseURI
    ) erc20Stablecoinwbtc(
        ethPriceSourceAddress,
        minimumCollateralPercentage,
        name,
        symbol,
        _mai,
        _collateral,
        meta,
        baseURI
    ) public {
        treasury=0;
    }

    function setGainRatio(uint256 _gainRatio) external onlyOwner() {
        gainRatio=_gainRatio;
    }

    function setDebtRatio(uint256 _debtRatio) external onlyOwner() {
        debtRatio=_debtRatio;
    }

    // management function
    function transferToken(address to, address token, uint256 amountToken) external onlyOwner() {
        ERC20(token).transfer(to, amountToken);
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

    function setMinCollateralRatio(uint256 minimumCollateralPercentage) external onlyOwner() {
        _minimumCollateralPercentage = minimumCollateralPercentage;
    }

    function setClosingFee(uint256 amount) external onlyOwner() {
        closingFee = amount;
    }

    function setOpeningFee(uint256 amount) external onlyOwner() {
        openingFee = amount;
    }

    function setTreasury(uint256 _treasury) external onlyOwner() {
        require(_exists(_treasury), "Vault does not exist");
        treasury = _treasury;
    }

    function transferToken(uint256 amountToken) public onlyOwner() {
        // Transfer reserve tokens back to main MAI contract
        mai.transfer(address(mai), amountToken);
    }

    function setBaseURI(string memory baseURI) public onlyOwner() {
        _setBaseURI(baseURI);
    }
}