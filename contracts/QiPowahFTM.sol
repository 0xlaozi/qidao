//SPDX-License-Identifier: Unlicense
pragma solidity 0.5.16;

import "@openzeppelin/contracts/math/SafeMath.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IMasterChef {
    function userInfo(uint256 nr, address who) external view returns (uint256, uint256);
    function pending(uint256 nr, address who) external view returns (uint256);
}

interface BalancerVault {
  function getPoolTokenInfo(bytes32, address) external view returns (uint256, uint256, uint256, address);
  function getPool(bytes32) external view returns (address, uint8);
}


contract QIPOWAHFTM {
    using SafeMath for uint256;
  
    function name() public pure returns(string memory) { return "QIPOWAHFTM"; }
    function symbol() public pure returns(string memory) { return "QIPOWAHFTM"; }
    function decimals() public pure returns(uint8) { return 18; }  

    function totalSupply() public view returns (uint256) {
        IERC20 qi = IERC20(0x68Aa691a8819B07988B18923F712F3f4C8d36346);// qidao erc20
        uint256 qi_totalQi = qi.totalSupply().mul(4); /// x 4 because boost in eQi

        return qi_totalQi;//lp_totalQi.add(qi_totalQi);
    }

    function calculateBalancerPoolBalance(bytes32 poolId, IERC20 token, address user) public view returns (uint256) {
        BalancerVault vault = BalancerVault(0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce);

        (address pool_address, ) = vault.getPool(poolId);
        (uint256 poolQiBalance, , , ) = vault.getPoolTokenInfo(poolId, address(token));
        return IERC20(pool_address).balanceOf(user).mul(poolQiBalance).div(IERC20(pool_address).totalSupply());
        /*     userShare = pool.balanceOf(userAddress) / pool.totalSupply()
        userQiBalance = userShare * poolQiBalance */
    }

    function balanceOf(address owner) public view returns (uint256) {
        IMasterChef chef = IMasterChef(0x230917f8a262bF9f2C3959eC495b11D1B7E1aFfC); // rewards/staking contract
        
        IERC20 qi = IERC20(0x68Aa691a8819B07988B18923F712F3f4C8d36346);// qidao erc20
        // Get Qi balance of user on Fantom
        uint256 qi_powah = qi.balanceOf(owner);
        
        // Get staked balance
        (uint256 lp_stakedBalance, ) = chef.userInfo(2, owner);        
        uint256 lp_powah = lp_stakedBalance;

        // Beethoven LP
        // QI-FTM
        qi_powah = qi_powah.add(calculateBalancerPoolBalance(0x7ae6a223cde3a17e0b95626ef71a2db5f03f540a00020000000000000000008a, qi, owner));

        // Add and return staked QI 
        return lp_powah.add(qi_powah);
    }

}
