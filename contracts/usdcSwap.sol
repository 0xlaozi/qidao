
// contracts/usdcSwap.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.5.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract usdcSwap is ReentrancyGuard {
    using SafeMath for uint256;

    address public admin;

    ERC20 usdc;
    ERC20 mimatic;

    uint256 public usdcRate;
    uint256 public mimaticRate;
    
    constructor(address _usdc, address _mimatic) public {
        admin = msg.sender;
        usdc = ERC20(_usdc);
        mimatic = ERC20(_mimatic);
        mimaticRate = 98;
        usdcRate = 102;
    }

    function setUSDCRatePerMimatic(uint256 _rate) public {
        require(admin==msg.sender, "ser pls no hack");
        usdcRate = _rate;
    }

    function setMimaticRatePerUSDC(uint256 _rate) public {
        require(admin==msg.sender, "ser pls no hack");
        mimaticRate = _rate;
    }
    
    function setAdmin(address _admin) public {
        require(admin==msg.sender, "ser pls no hack");
        admin=_admin;
    }

    function transferToken(address token, uint256 amountToken) public {
        require(admin==msg.sender, "ser pls no hack");
        ERC20(token).transfer(admin, amountToken);
    }

    // this returns the reserves in the contract

    function getReserves() public view returns(uint256, uint256) {
    	return ( mimatic.balanceOf(address(this)), usdc.balanceOf(address(this)) );
    }
    
    // the user must approve the balance so the contract can take it out of the user's account
    // else this will fail.

    function swapFrom(uint256 amount) public nonReentrant {
    	require(amount!=0, "swapFrom: invalid amount");
    	require(mimatic.balanceOf(address(this))!=0, "swapFrom: Not enough miMatic in reserves");

	    // for every 1.02 usdc we get 1.00 mimatic
	    	// 1020000 we get 1000000000000000000

	    uint256 amountToSend = amount.mul(100000000000000).div(usdcRate);

	    require(mimatic.balanceOf(address(this)) >= amountToSend, "swapFrom: Not enough miMatic in reserves");

	    // Transfer USDC to contract
	    usdc.transferFrom(msg.sender, address(this), amount);
	    // Transfer miMatic to sender
	    mimatic.transfer(msg.sender, amountToSend);
	}

    function swapTo(uint256 amount) public nonReentrant {
    	require(amount!=0, "swapTo: invalid amount");
    	require(usdc.balanceOf(address(this))!=0, "swapTo: Not enough USDC in reserves");
	    // for every 1.00 mimatic we get 0.98 usdc
	    	// 1000000000000000000 we get 980000 (bc decimals)
	    uint256 amountToSend = amount.mul(mimaticRate).div(100000000000000);

	    require(usdc.balanceOf(address(this)) >= amountToSend, "swapTo: Not enough miMatic in reserves");

	    // Tranfer tokens from sender to this contract
	    mimatic.transferFrom(msg.sender, address(this), amount);
	    // Transfer amount minus fees to sender
	    usdc.transfer(msg.sender, amountToSend);
	}
}
