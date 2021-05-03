pragma solidity 0.5.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./PriceSource.sol";

import "./IMyVault.sol";

contract Stablecoin is ERC20, ERC20Detailed, ReentrancyGuard {
    PriceSource public ethPriceSource;
    
    using SafeMath for uint256;

    uint256 private _minimumCollateralPercentage;

    IMyVault public erc721;

    uint256 public vaultCount;
    uint256 public debtCeiling;
    uint256 public closingFee;
    uint256 public openingFee;

    uint256 public treasury;
    uint256 public tokenPeg;

    mapping(uint256 => bool) public vaultExistence;
    mapping(uint256 => address) public vaultOwner;
    mapping(uint256 => uint256) public vaultCollateral;
    mapping(uint256 => uint256) public vaultDebt;

    address public stabilityPool;

    event CreateVault(uint256 vaultID, address creator);
    event DestroyVault(uint256 vaultID);
    event TransferVault(uint256 vaultID, address from, address to);
    event DepositCollateral(uint256 vaultID, uint256 amount);
    event WithdrawCollateral(uint256 vaultID, uint256 amount);
    event BorrowToken(uint256 vaultID, uint256 amount);
    event PayBackToken(uint256 vaultID, uint256 amount, uint256 closingFee);
    event BuyRiskyVault(uint256 vaultID, address owner, address buyer, uint256 amountPaid);

    constructor(
        address ethPriceSourceAddress,
        uint256 minimumCollateralPercentage,
        string memory name,
        string memory symbol,
        address vaultAddress
    ) ERC20Detailed(name, symbol, 18) public {
        assert(ethPriceSourceAddress != address(0));
        assert(minimumCollateralPercentage != 0);
                        //  | decimals start here
        debtCeiling=10000000000000000000;// 10 dollas
        closingFee=50; // 0.5%
        openingFee=0; // 0.0%
        ethPriceSource = PriceSource(ethPriceSourceAddress);
        stabilityPool=address(0);
        tokenPeg = 100000000; // $1

        erc721 = IMyVault(vaultAddress);
        _minimumCollateralPercentage = minimumCollateralPercentage;
    }

    modifier onlyVaultOwner(uint256 vaultID) {
        require(vaultExistence[vaultID], "Vault does not exist");
        require(vaultOwner[vaultID] == msg.sender, "Vault is not owned by you");
        _;
    }

    function getDebtCeiling() external view returns (uint256){
        return debtCeiling;
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
        (,int price,,,) = ethPriceSource.latestRoundData();
        return uint256(price);
    }

    function calculateCollateralProperties(uint256 collateral, uint256 debt) private view returns (uint256, uint256) {
        assert(getEthPriceSource() != 0);
        assert(getTokenPriceSource() != 0);

        uint256 collateralValue = collateral.mul(getEthPriceSource() );

        assert(collateralValue >= collateral);

        uint256 debtValue = debt.mul(getTokenPriceSource());

        assert(debtValue >= debt);

        uint256 collateralValueTimes100 = collateralValue.mul(100);

        assert(collateralValueTimes100 > collateralValue);

        return (collateralValueTimes100, debtValue);
    }

    function isValidCollateral(uint256 collateral, uint256 debt) private view returns (bool) {
        (uint256 collateralValueTimes100, uint256 debtValue) = calculateCollateralProperties(collateral, debt);

        uint256 collateralPercentage = collateralValueTimes100.div(debtValue);

        return collateralPercentage >= _minimumCollateralPercentage;
    }

    function createVault() external returns (uint256) {
        uint256 id = vaultCount;
        vaultCount = vaultCount.add(1);

        assert(vaultCount >= id);

        vaultExistence[id] = true;
        vaultOwner[id] = msg.sender;

        emit CreateVault(id, msg.sender);

        // mint erc721 (vaultId)

        erc721.mint(msg.sender,id);

        return id;
    }

    function destroyVault(uint256 vaultID) external onlyVaultOwner(vaultID) nonReentrant {
        require(vaultDebt[vaultID] == 0, "Vault has outstanding debt");

        if(vaultCollateral[vaultID]!=0) {
            msg.sender.transfer(vaultCollateral[vaultID]);
        }

        // burn erc721 (vaultId)

        erc721.burn(vaultID);

        delete vaultExistence[vaultID];
        delete vaultOwner[vaultID];
        delete vaultCollateral[vaultID];
        delete vaultDebt[vaultID];

        emit DestroyVault(vaultID);
    }

    function transferVault(uint256 vaultID, address to) external onlyVaultOwner(vaultID) {
        vaultOwner[vaultID] = to;

        // burn erc721 (vaultId)
        erc721.burn(vaultID);
        // mint erc721 (vaultId)
        erc721.mint(to,vaultID);

        emit TransferVault(vaultID, msg.sender, to);
    }

    function depositCollateral(uint256 vaultID) external payable onlyVaultOwner(vaultID) {
        uint256 newCollateral = vaultCollateral[vaultID].add(msg.value);

        assert(newCollateral >= vaultCollateral[vaultID]);

        vaultCollateral[vaultID] = newCollateral;

        emit DepositCollateral(vaultID, msg.value);
    }

    function withdrawCollateral(uint256 vaultID, uint256 amount) external onlyVaultOwner(vaultID) nonReentrant {
        require(vaultCollateral[vaultID] >= amount, "Vault does not have enough collateral");

        uint256 newCollateral = vaultCollateral[vaultID].sub(amount);

        if(vaultDebt[vaultID] != 0) {
            require(isValidCollateral(newCollateral, vaultDebt[vaultID]), "Withdrawal would put vault below minimum collateral percentage");
        }

        vaultCollateral[vaultID] = newCollateral;
        msg.sender.transfer(amount);

        emit WithdrawCollateral(vaultID, amount);
    }

    function borrowToken(uint256 vaultID, uint256 amount) external onlyVaultOwner(vaultID) {
        require(amount > 0, "Must borrow non-zero amount");
        require(totalSupply().add(amount) <= debtCeiling, "borrowToken: Cannot mint over totalSupply.");

        uint256 newDebt = vaultDebt[vaultID].add(amount);

        assert(newDebt > vaultDebt[vaultID]);

        require(isValidCollateral(vaultCollateral[vaultID], newDebt), "Borrow would put vault below minimum collateral percentage");

        vaultDebt[vaultID] = newDebt;
        _mint(msg.sender, amount);
        emit BorrowToken(vaultID, amount);
    }

    function payBackToken(uint256 vaultID, uint256 amount) external onlyVaultOwner(vaultID) {
        require(balanceOf(msg.sender) >= amount, "Token balance too low");
        require(vaultDebt[vaultID] >= amount, "Vault debt less than amount to pay back");

        uint256 _closingFee = (amount.mul(closingFee).mul(getTokenPriceSource())).div(getEthPriceSource().mul(10000));

        vaultDebt[vaultID] = vaultDebt[vaultID].sub(amount);
        vaultCollateral[vaultID]=vaultCollateral[vaultID].sub(_closingFee);
        vaultCollateral[treasury]=vaultCollateral[treasury].add(_closingFee);

        _burn(msg.sender, amount);

        emit PayBackToken(vaultID, amount, _closingFee);
    }

    function buyRiskyVault(uint256 vaultID) external {
        require(vaultExistence[vaultID], "Vault does not exist");
        require(stabilityPool==address(0) || msg.sender ==  stabilityPool, "buyRiskyVault disabled for public");

        (uint256 collateralValueTimes100, uint256 debtValue) = calculateCollateralProperties(vaultCollateral[vaultID], vaultDebt[vaultID]);

        uint256 collateralPercentage = collateralValueTimes100.div(debtValue);

        require(collateralPercentage < _minimumCollateralPercentage, "Vault is not below minimum collateral percentage");

        uint256 maximumDebtValue = collateralValueTimes100.div(_minimumCollateralPercentage);

        uint256 maximumDebt = maximumDebtValue.div(getTokenPriceSource() );

        uint256 debtDifference = vaultDebt[vaultID].sub(maximumDebt);

        require(balanceOf(msg.sender) >= debtDifference, "Token balance too low to pay off outstanding debt");

        address previousOwner = vaultOwner[vaultID];

        vaultOwner[vaultID] = msg.sender;
        vaultDebt[vaultID] = maximumDebt;

        uint256 _closingFee = (debtDifference.mul(closingFee).mul(getTokenPriceSource()) ).div(getEthPriceSource().mul(10000));
        vaultCollateral[vaultID]=vaultCollateral[vaultID].sub(_closingFee);
        vaultCollateral[treasury]=vaultCollateral[treasury].add(_closingFee);
        
        _burn(msg.sender, debtDifference);

        // burn erc721 (vaultId)
        erc721.burn(vaultID);
        // mint erc721 (vaultId)
        erc721.mint(msg.sender,vaultID);

        emit BuyRiskyVault(vaultID, previousOwner, msg.sender, debtDifference);
    }
}