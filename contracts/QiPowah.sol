/**
 *Submitted for verification at Etherscan.io on 2020-09-12
*/

pragma solidity 0.5.16;

import "@openzeppelin/contracts/math/SafeMath.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IPair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IMasterChef {
    function userInfo(uint256 nr, address who) external view returns (uint256, uint256);
    function pending(uint256 nr, address who) external view returns (uint256);
}

interface BalancerVault {
  function getPoolTokenInfo(bytes32, address) external view returns (uint256, uint256, uint256, address);
  function getPool(bytes32) external view returns (address, uint8);
}

contract QIPOWAH {
  using SafeMath for uint256;
  
  function name() public pure returns(string memory) { return "QIPOWAH"; }
  function symbol() public pure returns(string memory) { return "QIPOWAH"; }
  function decimals() public pure returns(uint8) { return 18; }  

  function totalSupply() public view returns (uint256) {
//    IPair pair = IPair(0x7AfcF11F3e2f01e71B7Cc6b8B5e707E42e6Ea397);
  // no xQi yet IBar bar = IBar(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);
    IERC20 qi = IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4);// qidao erc20
//    (uint256 lp_totalQi, , ) = pair.getReserves();
    uint256 qi_totalQi = qi.totalSupply().mul(4); /// x 4 because boost in eQi

    return qi_totalQi;//lp_totalQi.add(qi_totalQi);
  }
  
  function calculateBalanceInPair(address pair_addr, IERC20 token, address user) public view returns (uint256){
   
    IPair pair = IPair(pair_addr);

    uint256 lp_totalQi = token.balanceOf(address(pair));
    uint256 lp_balance = pair.balanceOf(user);
   
   if(lp_balance>0){
       return lp_totalQi.mul(lp_balance).div(pair.totalSupply());
   }else{
       return 0;
   }
  }

  function calculateBalancerPoolBalance(bytes32 poolId, IERC20 token, address user) public view returns (uint256) {
    BalancerVault vault = BalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    (address pool_address, ) = vault.getPool(poolId);
    (uint256 poolQiBalance, , , ) = vault.getPoolTokenInfo(poolId, address(token));
    return IERC20(pool_address).balanceOf(user).mul(poolQiBalance).div(IERC20(pool_address).totalSupply());
/*     userShare = pool.balanceOf(userAddress) / pool.totalSupply()

userQiBalance = userShare * poolQiBalance */
  }

  function balanceOf(address owner) public view returns (uint256) {
    IMasterChef chef = IMasterChef(0x574Fe4E8120C4Da1741b5Fd45584de7A5b521F0F); // rewards contract
    IPair QSpair = IPair(0x7AfcF11F3e2f01e71B7Cc6b8B5e707E42e6Ea397); // Qi-miMatic QS pair
    
  // no xQi yet  IBar bar = IBar(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);
    IERC20 qi = IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4);// qidao erc20

    IERC20 qix = IERC20(0xe1cA10e6a10c0F72B74dF6b7339912BaBfB1f8B5);// qix erc20

    IERC20 eqi = IERC20(0x880DeCADe22aD9c58A8A4202EF143c4F305100B3);// eqi erc20

    uint256 qi_powah = qi.balanceOf(owner).add(qix.balanceOf(owner));

    uint256 lp_totalQi = qi.balanceOf(address(QSpair));
    uint256 lp_balance = QSpair.balanceOf(owner);
    
    // Add staked balance
    (uint256 lp_stakedBalance, ) = chef.userInfo(2, owner);
    lp_balance = lp_balance.add(lp_stakedBalance);
    
    uint256 lp_powah =0;
    
    if( lp_balance>0 ){
        lp_powah= lp_totalQi.mul(lp_balance).div(QSpair.totalSupply());
        // all Qi in lp * user_lp_balance / total_lp_balance
    }
    
    // add any unharvested Qi from the qi-mimatic staked pool
    qi_powah = qi_powah.add(chef.pending(0, owner));
    qi_powah = qi_powah.add(chef.pending(1, owner));
    qi_powah = qi_powah.add(chef.pending(2, owner));
    
    // need to add nonincentivized farms as well

    // qi-wmatic QS pair
    qi_powah = qi_powah.add(calculateBalanceInPair(0x7AfcF11F3e2f01e71B7Cc6b8B5e707E42e6Ea397, qi, owner));
    // USDC-Qi pair
    qi_powah = qi_powah.add(calculateBalanceInPair(0x1dBba57B3d9719c007900D21e8541e90bC6933EC, qi, owner));
    // QI - QUICK pair
    qi_powah = qi_powah.add(calculateBalanceInPair(0x25d56E2416f20De1Efb1F18fd06dD12eFeC3D3D0, qi, owner));
    
    // sushi pairs
    // wmatic-qi
    qi_powah = qi_powah.add(calculateBalanceInPair(0xCe00673a5a3023EBE47E3D46e4D59292e921dc7c, qi, owner));
    // mimatic-qi
    qi_powah = qi_powah.add(calculateBalanceInPair(0x96f72333A043a623D6869954B6A50AB7Be883EbC, qi, owner));

    // Balancer LP
    // WMATIC-USDC-QI-BAL-MIMATIC
    qi_powah = qi_powah.add(calculateBalancerPoolBalance(0xf461f2240b66d55dcf9059e26c022160c06863bf000100000000000000000006, qi, owner));
    // SUSHI-WMATIC-USDC-QI-WETH-QUICK-BAL-ADDY
    qi_powah = qi_powah.add(calculateBalancerPoolBalance(0x32fc95287b14eaef3afa92cccc48c285ee3a280a000100000000000000000005, qi, owner));
    // QI-MIMATIC
    qi_powah = qi_powah.add(calculateBalancerPoolBalance(0x09804caea2400035b18e2173fdd10ec8b670ca0900020000000000000000000f, qi, owner));

    // add eQi
    qi_powah = qi_powah.add(eqi.balanceOf(owner));

    return lp_powah.add(qi_powah);
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}