// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

// escrowed Qi (eQi)
// This contract lets you lock your Qi for up to 4 years
// giving you a Qi Dao platform multiplier (up to 4x) which can be used across its products.

contract eQi is ERC20, ReentrancyGuard, Ownable, ERC20Detailed("escrowed Qi", "eQi", 18) {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    IERC20 public Qi = IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4);// qidao erc20

    struct UserInfo {
        uint256 amount;
        uint256 endBlock;
    }

    event UpdateMultiplier(uint8 mult);
    event UpdateMaxLock(uint256 max);

    uint8 multiplier = 3;
    uint256 maxLock = 60108430;

    bool emergency = false;

    mapping(address => UserInfo) public userInfo;

    event Enter(address user, uint256 amount, uint256 endBlock);
    event Leave(address user, uint256 amount, uint256 endBlock);

    function updateMultiplier(uint8 _multiplier) public onlyOwner() {
        multiplier = _multiplier;
        emit UpdateMultiplier(multiplier);
    }

    function updateMaxLock(uint256 _maxLock) public onlyOwner() {
        maxLock = _maxLock;
        emit UpdateMaxLock(maxLock);
    }

    function enter(uint256 _amount, uint256 _blockNumber) public nonReentrant {

        if(userInfo[msg.sender].endBlock == 0 || userInfo[msg.sender].endBlock <= block.number){
            userInfo[msg.sender].endBlock = block.number;
        }

        require(
                userInfo[msg.sender].endBlock.add(_blockNumber) <= maxLock.add(block.number), 
                    "enter: blockNumber cannot be more than 4 years from now.");
        
        require(Qi.balanceOf(msg.sender)>=_amount, "enter: balanceOf(msg.sender) less than amount");

        if(_amount != 0){
            Qi.safeTransferFrom(msg.sender, address(this), _amount);
            userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(_amount);
        }

        if(_blockNumber != 0){
            userInfo[msg.sender].endBlock = userInfo[msg.sender].endBlock.add(_blockNumber);
        }

        emit Enter(msg.sender, userInfo[msg.sender].amount, userInfo[msg.sender].endBlock);
    }

    function leave() public nonReentrant {
        require(userInfo[msg.sender].endBlock <= block.number, "leave: tokens are still locked.");

        Qi.safeTransfer(msg.sender, userInfo[msg.sender].amount);

        emit Leave(msg.sender, userInfo[msg.sender].amount, userInfo[msg.sender].endBlock);

        delete userInfo[msg.sender].amount;
        delete userInfo[msg.sender].endBlock;
    }

    function endBlock() public view returns (uint256) {
        return userInfo[msg.sender].endBlock;
    }

    function balanceOf(address user) public view returns (uint256){
        // it starts as *3+1 for a 4x-max boost
        if (userInfo[user].endBlock <= block.number || userInfo[user].amount == 0){
            return userInfo[user].amount;
        } else{
            return currentMultiplier(user).div(maxLock).div(1000).add(userInfo[user].amount);
        }
    }

    function currentMultiplier(address user) private view returns (uint256) {
        return userInfo[user].endBlock.sub(block.number).mul(userInfo[user].amount).mul(multiplier).mul(1000);
    }

    function underlyingBalance(address user) public view returns (uint256) {
        return userInfo[user].amount;
    }

    function setEmergency(bool _trigger) public onlyOwner() {
        emergency=_trigger;
    }

    function emergencyExit() public {
        require(emergency, "emergency: not enabled");
        uint256 withdraw = userInfo[msg.sender].amount;
        userInfo[msg.sender].amount = 0;
        userInfo[msg.sender].endBlock = 0;
        Qi.safeTransfer(msg.sender, withdraw);
    }

    // no transfers, nothing
    function allowance(address, address) public view returns (uint256) { return 0; }
    function transfer(address, uint256) public returns (bool) { return false; }
    function approve(address, uint256) public returns (bool) { return false; }
    function transferFrom(address, address, uint256) public returns (bool) { return false; }
}