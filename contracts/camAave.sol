// contracts/shareOracle.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IAaveIncentivesController.sol";
import "./interfaces/ILendingPool.sol";

interface Uni {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;
}

// stake Token to earn more Token (from farming)
contract camAave is ERC20, ERC20Detailed {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address public Token;
    address public AaveContract;
    address public wMatic;
    address public constant LENDING_POOL = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;

    address public uni; // QuickSwap
    address public treasury;
    
    address public operator;

    address public aave;
    address public weth;

    uint16 public depositFeeBP;

    // Define the compounding aave market token contract
    constructor(address amToken, address underlying, string memory name, string memory symbol, uint8 decimals) ERC20Detailed(name, symbol, decimals) public {

        Token=amToken; //amaave
        aave=underlying;

        AaveContract = 0x357D51124f59836DeD84c8a1730D72B749d8BC23; // aave incentives controller
        wMatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
        uni =  0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // quickswap
        treasury = 0x86fE8d6D4C8A007353617587988552B6921514Cb;
        depositFeeBP = 0;

        operator = address(0);
    }

    modifier onlyOperator() {
        require(operator==address(0) || msg.sender ==  operator, "onlyOperator: not allowed");
        _;
    }

    function updateOperator(address _operator) public {
        require(treasury==msg.sender, "updateOperator: not allowed.");
        operator=_operator;
    }

    function updateTreasury(address _treasury) public {
        require(treasury==msg.sender, "updateTreasury: not allowed.");
        treasury=_treasury;
    }

    function updateUniV2Router(address _router) public {
        require(treasury==msg.sender, "updateUniV2Router: not allowed.");
        uni=_router;
    }

    function updateDepositFee(uint16 _depositFee) public {
        require(treasury==msg.sender, "updateDepositFee: not allowed.");
        depositFeeBP=_depositFee;
    }

    // Locks amToken and mints camToken (shares)
    function enter(uint256 _amount) public {        
        uint256 totalTokenLocked = IERC20(Token).balanceOf(address(this));

        uint256 totalShares = totalSupply(); // Gets the amount of camToken in existence

        // Lock the Token in the contract
        IERC20(Token).transferFrom(msg.sender, address(this), _amount);
        
        if (totalShares == 0 || totalTokenLocked == 0) { // If no camToken exists, mint it 1:1 to the amount put in
            if(depositFeeBP > 0){
                // calculate depositFeeBP
                uint256 depositFee = _amount.mul(depositFeeBP).div(10000);
                _mint(treasury, depositFee);
                _mint(msg.sender, _amount.sub(depositFee));
            }else{
                _mint(msg.sender, _amount);
            }
        } else {
            uint256 camTokenAmount = _amount.mul(totalShares).div(totalTokenLocked);
            if(depositFeeBP > 0){
                uint256 depositFee = camTokenAmount.mul(depositFeeBP).div(10000);
                _mint(treasury, depositFee);
                _mint(msg.sender, camTokenAmount.sub(depositFee));
            }else{
                _mint(msg.sender, camTokenAmount);
            }
        }
    }

    function claimAaveRewards() public onlyOperator() {
        // we're only checking for one asset (Token which is an interest bearing amToken)
        address[] memory rewardsPath = new address[](1);
                rewardsPath[0] = Token;

        // check how many matic are available to claim
        uint256 rewardBalance = IAaveIncentivesController(AaveContract).getRewardsBalance(rewardsPath, address(this));

        // we should only claim rewards if its over 0.
        if(rewardBalance > 2){
            IAaveIncentivesController(AaveContract).claimRewards(rewardsPath, rewardBalance, address(this));
        }
    }
    
    function harvestMaticIntoToken() public onlyOperator() {
        // claims any available Matic from the Aave Incentives contract.

        uint256 _wmaticBalance = IERC20(wMatic).balanceOf(address(this));

        if(_wmaticBalance > 2) {
            address[] memory path = new address[](3);
                path[0] = wMatic;
                path[1] = weth;
                path[2] = aave;
    
            IERC20(wMatic).safeApprove(uni, 0);
            IERC20(wMatic).safeApprove(uni, _wmaticBalance);
            
            // if successful this should increase the total MiMatic held by contract
            Uni(uni).swapExactTokensForTokens(_wmaticBalance, uint256(0), path, address(this), now.add(1800));
            
            uint256 newBalance = IERC20(aave).balanceOf(address(this));

            // Just being safe
            IERC20(aave).safeApprove(LENDING_POOL, 0);
            // Approve Transfer _amount aave to lending pool
            IERC20(aave).safeApprove(LENDING_POOL, newBalance);
            // then we need to deposit it into the lending pool
            ILendingPool(LENDING_POOL).deposit(aave, newBalance, address(this), 0);
        }
    }

    // claim amToken by burning camToken
    function leave(uint256 _share) public {
        if(_share>0){
            uint256 totalShares = totalSupply(); // Gets the amount of camToken in existence

            uint256 amTokenAmount = _share.mul(IERC20(Token).balanceOf(address(this))).div(totalShares);
            _burn(msg.sender, _share);
            
            // Now we withdraw the amToken from the camToken Pool and send to user as amToken.
            //IERC20(aave).safeApprove(address(this), amTokenAmount);
            IERC20(Token).transfer(msg.sender, amTokenAmount);
        }
    }
}