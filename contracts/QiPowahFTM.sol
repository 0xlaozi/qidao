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

    function balanceOf(address owner) public view returns (uint256) {
        IMasterChef chef = IMasterChef(0x230917f8a262bF9f2C3959eC495b11D1B7E1aFfC); // rewards/staking contract
        IERC20 beetsPair = IERC20(0x7aE6A223cde3A17E0B95626ef71A2DB5F03F540A); //Qi-miMatic beets pair

        IERC20 qi = IERC20(0x68Aa691a8819B07988B18923F712F3f4C8d36346);// qidao erc20

        // Get Qi balance of user on Fantom
        uint256 qi_powah = qi.balanceOf(owner);

        // Total Qi held in beets pair
        uint256 lp_totalQi = qi.balanceOf(address(beetsPair));
        // Beets pair tokens held by owner
        uint256 lp_balance = beetsPair.balanceOf(owner);
        
        // Get staked balance of owner
        (uint256 lp_stakedBalance, ) = chef.userInfo(2, owner);   
        lp_balance = lp_balance.add(lp_stakedBalance);

        uint256 lp_powah = 0;
        if (lp_balance > 0) {
            // QI Balance of the beets pair * (the staked + non staked LP balance of the owner) / all the lp tokens for the pair
            lp_powah = lp_totalQi.mul(lp_balance).div(beetsPair.totalSupply());
        }

        qi_powah = qi_powah.add(chef.pending(0, owner)); // Unclaimed reward Qi from WFTM-Qi
        qi_powah = qi_powah.add(chef.pending(1, owner)); // Unclaimed reward Qi from USDC-miMatic

        // Add and return staked QI 
        return lp_powah.add(qi_powah);
    }
}
