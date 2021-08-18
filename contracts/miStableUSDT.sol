
// contracts/miStableUSDT.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.5.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract miStableUSDT is ReentrancyGuard {
    using SafeMath for uint256;

    address public admin;

    ERC20 usdt;
    ERC20 mai;

    uint256 public usdtRate;
    uint256 public maiRate;
    
    constructor(address _usdt, address _mai) public {
        admin = msg.sender;
        usdt = ERC20(_usdt);
        mai = ERC20(_mai);
        maiRate = 99;
        usdtRate = 101;
    }

    function setUSDCRatePerMimatic(uint256 _rate) public {
        require(admin==msg.sender, "ser pls no hack");
        usdtRate = _rate;
    }

    function setMimaticRatePerUSDC(uint256 _rate) public {
        require(admin==msg.sender, "ser pls no hack");
        maiRate = _rate;
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
        return ( mai.balanceOf(address(this)), usdt.balanceOf(address(this)) );
    }
    
    // the user must approve the balance so the contract can take it out of the user's account
    // else this will fail.

    function swapFrom(uint256 amount) public nonReentrant {
        require(amount!=0, "swapFrom: invalid amount");
        require(mai.balanceOf(address(this))!=0, "swapFrom: Not enough miMatic in reserves");

        // for every 1.02 usdt we get 1.00 mai
            // 1020000 we get 1000000000000000000

        uint256 amountToSend = amount.mul(100000000000000).div(usdtRate);

        require(mai.balanceOf(address(this)) >= amountToSend, "swapFrom: Not enough miMatic in reserves");

        // Transfer USDC to contract
        usdt.transferFrom(msg.sender, address(this), amount);
        // Transfer miMatic to sender
        mai.transfer(msg.sender, amountToSend);
    }

    function swapTo(uint256 amount) public nonReentrant {
        require(amount!=0, "swapTo: invalid amount");
        require(usdt.balanceOf(address(this))!=0, "swapTo: Not enough USDC in reserves");
        // for every 1.00 mai we get 0.98 usdt
            // 1000000000000000000 we get 980000 (bc decimals)
        uint256 amountToSend = amount.mul(maiRate).div(100000000000000);

        require(usdt.balanceOf(address(this)) >= amountToSend, "swapTo: Not enough miMatic in reserves");

        // Tranfer tokens from sender to this contract
        mai.transferFrom(msg.sender, address(this), amount);
        // Transfer amount minus fees to sender
        usdt.transfer(msg.sender, amountToSend);
    }
}
