pragma solidity 0.5.16;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../PriceSource.sol";

import "../MyVaultV3.sol";

contract erc20Stablecoinwbtc is ReentrancyGuard, VaultNFTv3 {
    PriceSource public ethPriceSource;
    
    using SafeMath for uint256;
    using SafeERC20 for ERC20Detailed;

    uint256 public _minimumCollateralPercentage;

    uint256 public vaultCount;
    uint256 public closingFee;
    uint256 public openingFee;

    uint256 public treasury;
    uint256 public tokenPeg;

    mapping(uint256 => uint256) public vaultCollateral;
    mapping(uint256 => uint256) public vaultDebt;

    uint256 public debtRatio;
    uint256 public gainRatio;

    address public stabilityPool;

    ERC20Detailed public collateral;

    ERC20Detailed public mai;

    uint8 public priceSourceDecimals;

    event CreateVault(uint256 vaultID, address creator);
    event DestroyVault(uint256 vaultID);
    event TransferVault(uint256 vaultID, address from, address to);
    event DepositCollateral(uint256 vaultID, uint256 amount);
    event WithdrawCollateral(uint256 vaultID, uint256 amount);
    event BorrowToken(uint256 vaultID, uint256 amount);
    event PayBackToken(uint256 vaultID, uint256 amount, uint256 closingFee);
    event LiquidateVault(uint256 vaultID, address owner, address buyer, uint256 debtRepaid, uint256 collateralLiquidated, uint256 closingFee);

    mapping(address => uint256) public maticDebt;

    constructor(
        address ethPriceSourceAddress,
        uint256 minimumCollateralPercentage,
        string memory name,
        string memory symbol,
        address _mai,
        address _collateral,
        address meta,
        string memory baseURI
    ) VaultNFTv3(name, symbol, meta, baseURI) public {
        assert(ethPriceSourceAddress != address(0));
        assert(minimumCollateralPercentage != 0);
                        //  | decimals start here
        closingFee=50; // 0.5%
        openingFee=0; // 0.0%
        ethPriceSource = PriceSource(ethPriceSourceAddress);
        stabilityPool = address(0);
        tokenPeg = 100000000; // $1

        debtRatio = 2; // 1/2, pay back 50%
        gainRatio = 1100;// /10 so 1.1

        _minimumCollateralPercentage = minimumCollateralPercentage;

        collateral = ERC20Detailed(_collateral);
        mai = ERC20Detailed(_mai);
        priceSourceDecimals = ethPriceSource.decimals();
    }

    modifier onlyVaultOwner(uint256 vaultID) {
        require(_exists(vaultID), "Vault does not exist");
        require(ownerOf(vaultID) == msg.sender, "Vault is not owned by you");
        _;
    }

    function getDebtCeiling() public view returns (uint256){
        return mai.balanceOf(address(this));
    }

    function exists(uint256 vaultID) external view returns (bool){
        return _exists(vaultID);
    }

    function getClosingFee() external view returns (uint256){
        return closingFee;
    }

    function getOpeningFee() external view returns (uint256){
        return openingFee;
    }

    function getTokenPriceSource() public view returns (uint256){
        return tokenPeg;
    }

    function getEthPriceSource() public view returns (uint256){
        (,int256 price,,,) = ethPriceSource.latestRoundData();
        return uint256(price); // brings it back to 18.
    }

    function calculateCollateralProperties(uint256 _collateral, uint256 _debt) private view returns (uint256, uint256) {

        assert(getEthPriceSource() != 0);
        assert(getTokenPriceSource() != 0);

        uint256 collateralValue = _collateral.mul(getEthPriceSource());

        assert(collateralValue >= _collateral);

        uint256 debtValue = _debt.mul(getTokenPriceSource());

        assert(debtValue >= _debt);

        uint256 collateralValueTimes100 = collateralValue.mul(100);

        assert(collateralValueTimes100 > collateralValue);

        return (collateralValueTimes100, debtValue);
    }

    function isValidCollateral(uint256 _collateral, uint256 debt) private view returns (bool) {
        (uint256 collateralValueTimes100, uint256 debtValue) = calculateCollateralProperties(_collateral, debt);

        uint256 collateralPercentage = collateralValueTimes100.mul(10 ** 10).div(debtValue);

        return collateralPercentage >= _minimumCollateralPercentage;
    }

    function createVault() external returns (uint256) {
        uint256 id = vaultCount;
        vaultCount = vaultCount.add(1);

        assert(vaultCount >= id);

        _mint(msg.sender,id);

        emit CreateVault(id, msg.sender);

        return id;
    }

    function destroyVault(uint256 vaultID) external onlyVaultOwner(vaultID) nonReentrant {
        require(vaultDebt[vaultID] == 0, "Vault has outstanding debt");

        if(vaultCollateral[vaultID]!=0) {
            // withdraw leftover collateral
            collateral.safeTransfer(ownerOf(vaultID), vaultCollateral[vaultID]);
        }

        _burn(vaultID);

        delete vaultCollateral[vaultID];
        delete vaultDebt[vaultID];

        emit DestroyVault(vaultID);
    }

    function depositCollateral(uint256 vaultID, uint256 amount) external {

        collateral.safeTransferFrom(msg.sender, address(this), amount);

        uint256 newCollateral = vaultCollateral[vaultID].add(amount);

        assert(newCollateral >= vaultCollateral[vaultID]);

        vaultCollateral[vaultID] = newCollateral;

        emit DepositCollateral(vaultID, amount);
    }

    function withdrawCollateral(uint256 vaultID, uint256 amount) external onlyVaultOwner(vaultID) nonReentrant {
        require(vaultCollateral[vaultID] >= amount, "Vault does not have enough collateral");

        uint256 newCollateral = vaultCollateral[vaultID].sub(amount);

        if(vaultDebt[vaultID] != 0) {
            require(isValidCollateral(newCollateral, vaultDebt[vaultID]), "Withdrawal would put vault below minimum collateral percentage");
        }

        vaultCollateral[vaultID] = newCollateral;
        collateral.safeTransfer(msg.sender, amount);

        emit WithdrawCollateral(vaultID, amount);
    }

    function borrowToken(uint256 vaultID, uint256 amount) external onlyVaultOwner(vaultID) {
        require(amount > 0, "Must borrow non-zero amount");
        require(amount <= getDebtCeiling(), "borrowToken: Cannot mint over available supply.");

        uint256 newDebt = vaultDebt[vaultID].add(amount);

        assert(newDebt > vaultDebt[vaultID]);

        require(isValidCollateral(vaultCollateral[vaultID], newDebt), "Borrow would put vault below minimum collateral percentage");

        vaultDebt[vaultID] = newDebt;

        // mai
        mai.safeTransfer(msg.sender, amount);

        emit BorrowToken(vaultID, amount);
    }

    function payBackToken(uint256 vaultID, uint256 amount) external {
        require(mai.balanceOf(msg.sender) >= amount, "Token balance too low");
        require(vaultDebt[vaultID] >= amount, "Vault debt less than amount to pay back");

        uint256 _closingFee = (amount.mul(closingFee).mul(getTokenPriceSource()) ).div(getEthPriceSource().mul(10000)).div(1000000000);

        //mai
        mai.safeTransferFrom(msg.sender, address(this), amount);

        vaultDebt[vaultID] = vaultDebt[vaultID].sub(amount);
        vaultCollateral[vaultID]=vaultCollateral[vaultID].sub(_closingFee);
        vaultCollateral[treasury]=vaultCollateral[treasury].add(_closingFee);

        emit PayBackToken(vaultID, amount, _closingFee);
    }

    function getPaid() public nonReentrant {
        require(maticDebt[msg.sender]!=0, "Don't have anything for you.");
        uint256 amount = maticDebt[msg.sender];
        maticDebt[msg.sender]=0;
        collateral.safeTransfer(msg.sender, amount);
    }

    function checkCost(uint256 vaultID) public view returns (uint256) {

        if(vaultCollateral[vaultID] == 0 || vaultDebt[vaultID]==0 || !checkLiquidation(vaultID) ){
            return 0;
        }

        (uint256 collateralValueTimes100, uint256 debtValue) = calculateCollateralProperties(vaultCollateral[vaultID], vaultDebt[vaultID]);

        if(debtValue==0){
            return 0;
        }
        
        uint256 collateralPercentage = collateralValueTimes100.div(debtValue);

        debtValue = debtValue.div(10 ** 8);

        uint256 halfDebt = debtValue.div(debtRatio); //debtRatio (2)

        return(halfDebt);
    }

    function checkExtract(uint256 vaultID) public view returns (uint256) {

        if(vaultCollateral[vaultID] == 0|| !checkLiquidation(vaultID) ) {
            return 0;
        }

        (uint256 collateralValueTimes100, uint256 debtValue) = calculateCollateralProperties(vaultCollateral[vaultID], vaultDebt[vaultID]);

        uint256 halfDebt = debtValue.div(debtRatio); //debtRatio (2)

        if(halfDebt==0){
            return 0;
        }
        return halfDebt.mul(gainRatio).div(1000).div(getEthPriceSource()).div(10000000000);
    }

    function checkCollateralPercentage(uint256 vaultID) public view returns(uint256){
        require(_exists(vaultID), "Vault does not exist");

        if(vaultCollateral[vaultID] == 0 || vaultDebt[vaultID]==0){
            return 0;
        }
        (uint256 collateralValueTimes100, uint256 debtValue) = calculateCollateralProperties(vaultCollateral[vaultID], vaultDebt[vaultID]);

        collateralValueTimes100 = collateralValueTimes100.mul(10 ** 10);

        return collateralValueTimes100.div(debtValue);
    }

    function checkLiquidation(uint256 vaultID) public view returns (bool) {
        require(_exists(vaultID), "Vault does not exist");
        
        if(vaultCollateral[vaultID] == 0 || vaultDebt[vaultID]==0){
            return false;
        }

        (uint256 collateralValueTimes100, uint256 debtValue) = calculateCollateralProperties(vaultCollateral[vaultID], vaultDebt[vaultID]);

        collateralValueTimes100 = collateralValueTimes100.mul(10 ** 10);

        uint256 collateralPercentage = collateralValueTimes100.div(debtValue);

        if(collateralPercentage < _minimumCollateralPercentage){
            return true;
        } else{
            return false;
        }
    }

    function liquidateVault(uint256 vaultID) external {
        require(_exists(vaultID), "Vault does not exist");
        require(stabilityPool==address(0) || msg.sender ==  stabilityPool, "liquidation is disabled for public");

        (uint256 collateralValueTimes100, uint256 debtValue) = calculateCollateralProperties(vaultCollateral[vaultID], vaultDebt[vaultID]);
        
        collateralValueTimes100 = collateralValueTimes100.mul(10 ** 10);

        uint256 collateralPercentage = collateralValueTimes100.div(debtValue);

        require(collateralPercentage < _minimumCollateralPercentage, "Vault is not below minimum collateral percentage");

        debtValue = debtValue.div(10 ** 8);

        uint256 halfDebt = debtValue.div(debtRatio); //debtRatio (2)

        require(mai.balanceOf(msg.sender) >= halfDebt, "Token balance too low to pay off outstanding debt");

        //mai
        mai.safeTransferFrom(msg.sender, address(this), halfDebt);

        uint256 maticExtract = checkExtract(vaultID);

        vaultDebt[vaultID] = vaultDebt[vaultID].sub(halfDebt); // we paid back half of its debt.

        uint256 _closingFee = (halfDebt.mul(closingFee).mul(getTokenPriceSource()) ).div(getEthPriceSource().mul(10000)).div(1000000000);
     
        vaultCollateral[vaultID]=vaultCollateral[vaultID].sub(_closingFee);
        vaultCollateral[treasury]=vaultCollateral[treasury].add(_closingFee);

        // deduct the amount from the vault's collateral
        vaultCollateral[vaultID] = vaultCollateral[vaultID].sub(maticExtract);

        // let liquidator take the collateral
        maticDebt[msg.sender] = maticDebt[msg.sender].add(maticExtract);

        emit LiquidateVault(vaultID, ownerOf(vaultID), msg.sender, halfDebt, maticExtract, _closingFee);
    }
}