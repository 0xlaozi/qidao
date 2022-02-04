/**
 *Submitted for verification at Etherscan.io on 2020-09-12
 */

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

interface IStakingRewards {
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function totalSupply() external view returns (uint256);
}

interface IPair {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function getReserves()
  external
  view
  returns (
    uint112,
    uint112,
    uint32
  );
}

interface IVault {
  function balance() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function totalSupply() external view returns (uint256);
}

interface IJar {
  function balanceOf(address _user) external view returns (uint256);

  function getRatio() external view returns (uint256);
}

interface IPickleFarm {
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
  }

  function userInfo(uint256 index, address user)
  external
  view
  returns (UserInfo memory);
}

interface IMasterChef {
  function userInfo(uint256 nr, address who)
  external
  view
  returns (uint256, uint256);

  function pending(uint256 nr, address who) external view returns (uint256);
}

interface BalancerVault {
  function getPoolTokenInfo(bytes32, address)
  external
  view
  returns (
    uint256,
    uint256,
    uint256,
    address
  );

  function getPool(bytes32) external view returns (address, uint8);
}

contract QIPOWAH {
  using SafeMath for uint256;

  IERC20 qi = IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4);

  function name() public pure returns (string memory) {
    return "QIPOWAH";
  }

  function symbol() public pure returns (string memory) {
    return "QIPOWAH";
  }

  function decimals() public pure returns (uint8) {
    return 18;
  }

  function totalSupply() public view returns (uint256) {
    //    IPair pair = IPair(0x7AfcF11F3e2f01e71B7Cc6b8B5e707E42e6Ea397);
    // no xQi yet IBar bar = IBar(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);
    //    (uint256 lp_totalQi, , ) = pair.getReserves();
    uint256 qi_totalQi = qi.totalSupply().mul(4); /// x 4 because boost in eQi

    return qi_totalQi; //lp_totalQi.add(qi_totalQi);
  }

  function calculateBalanceInPair(
    address pair_addr,
    IERC20 token,
    address user
  ) public view returns (uint256) {
    IPair pair = IPair(pair_addr);

    uint256 lp_totalQi = token.balanceOf(address(pair));
    uint256 lp_balance = pair.balanceOf(user);
    if (lp_balance > 0) {
      return lp_totalQi.mul(lp_balance).div(pair.totalSupply());
    } else {
      return 0;
    }
  }

  function calculateBalanceInQuickSwapStakingPool(
    address pool_addr,
    address pair_addr,
    IERC20 token,
    address user
  ) public view returns (uint256) {
    IPair pair = IPair(pair_addr);
    IStakingRewards stakingRewards = IStakingRewards(pool_addr);

    return stakingRewards
    .balanceOf(user)
    .mul(token.balanceOf(pair_addr))
    .mul(pair.balanceOf(pool_addr))
    .div(stakingRewards.totalSupply())
    .div(pair.totalSupply());
  }

  function lpToQi(address pair_addr, uint256 lpTokens)
  public
  view
  returns (uint256)
  {
    IPair pool = IPair(pair_addr);

    uint256 lp_totalQi = qi.balanceOf(address(pool));
    return lp_totalQi.mul(lpTokens).div(pool.totalSupply());
  }

  function calculateAddyPower(
    address jar_addr,
    address pair_addr,
    address user
  ) public view returns (uint256) {
    IJar addyJar = IJar(jar_addr);
    uint256 LPTokens = addyJar.balanceOf(user).mul(addyJar.getRatio()).div(
      1e18
    );
    return lpToQi(pair_addr, LPTokens);
  }

  function calculateBeefyPower(
    address vault_addr,
    address pair_addr,
    address user
  ) public view returns (uint256) {
    IVault beefyVault = IVault(vault_addr);
    uint256 userBalance = beefyVault.balanceOf(user);
    uint256 userLpTokens = (
    userBalance.mul(beefyVault.balance()).div(beefyVault.totalSupply())
    );
    return lpToQi(pair_addr, userLpTokens);
  }

  function calculatePickleJarPower(
    address jar_addr,
    address pair_addr,
    address user
  ) public view returns (uint256) {
    IJar pickleJar = IJar(jar_addr);
    uint256 LPTokens = pickleJar
    .balanceOf(user)
    .mul(pickleJar.getRatio())
    .div(1e18);
    return lpToQi(pair_addr, LPTokens);
  }

  function calculatePickleFarmPower(
    address farm_addr,
    address jar_addr,
    address pair_addr,
    address user
  ) public view returns (uint256) {
    IJar pickleJar = IJar(jar_addr);
    IPickleFarm pickleFarm = IPickleFarm(farm_addr);
    IPickleFarm.UserInfo memory userInfo = pickleFarm.userInfo(10, user);
    uint256 LPTokens = userInfo.amount.mul(pickleJar.getRatio()).div(1e18);
    return lpToQi(pair_addr, LPTokens);
  }

  function calculateBalancerPoolBalance(
    bytes32 poolId,
    IERC20 token,
    address user
  ) public view returns (uint256) {
    BalancerVault vault = BalancerVault(
      0xBA12222222228d8Ba445958a75a0704d566BF2C8
    );
    (address pool_address, ) = vault.getPool(poolId);
    (uint256 poolQiBalance, , , ) = vault.getPoolTokenInfo(
      poolId,
      address(token)
    );
    return
    IERC20(pool_address).balanceOf(user).mul(poolQiBalance).div(
      IERC20(pool_address).totalSupply()
    );
    /*     userShare = pool.balanceOf(userAddress) / pool.totalSupply()

userQiBalance = userShare * poolQiBalance */
  }

  function getAllFarms(uint256 qi_powah, address owner) public view returns (uint256) {

    // qi-mimatic QS pair
    qi_powah = qi_powah.add(
      calculateBalanceInPair(
        0x7AfcF11F3e2f01e71B7Cc6b8B5e707E42e6Ea397,
        qi,
        owner
      )
    );
    // USDC-Qi pair
    qi_powah = qi_powah.add(
      calculateBalanceInPair(
        0x1dBba57B3d9719c007900D21e8541e90bC6933EC,
        qi,
        owner
      )
    );
    // QI - QUICK pair
    qi_powah = qi_powah.add(
      calculateBalanceInPair(
        0x25d56E2416f20De1Efb1F18fd06dD12eFeC3D3D0,
        qi,
        owner
      )
    );

    // QI - WETH
    qi_powah = qi_powah.add(
      calculateBalanceInPair(
        0x8C1b40Ea78081B70F661C3286c74E71b4602C9C0,
        qi,
        owner
      )
    );

    // QI - WMATIC
    qi_powah = qi_powah.add(
      calculateBalanceInPair(
        0x9A8b2601760814019B7E6eE0052E25f1C623D1E6,
        qi,
        owner
      )
    );

    // QI - DAI
    qi_powah = qi_powah.add(
      calculateBalanceInPair(
        0xe7519Be0E2A4450815858343ca480d1939bE7281,
        qi,
        owner
      )
    );

    // sushi pairs
    // wmatic-qi
    qi_powah = qi_powah.add(
      calculateBalanceInPair(
        0xCe00673a5a3023EBE47E3D46e4D59292e921dc7c,
        qi,
        owner
      )
    );
    // mimatic-qi
    qi_powah = qi_powah.add(
      calculateBalanceInPair(
        0x96f72333A043a623D6869954B6A50AB7Be883EbC,
        qi,
        owner
      )
    );

    // Balancer LP
    // WMATIC-USDC-QI-BAL-MIMATIC
    qi_powah = qi_powah.add(
      calculateBalancerPoolBalance(
        0xf461f2240b66d55dcf9059e26c022160c06863bf000100000000000000000006,
        qi,
        owner
      )
    );

    // SUSHI-WMATIC-USDC-QI-WETH-QUICK-BAL-ADDY
    qi_powah = qi_powah.add(
      calculateBalancerPoolBalance(
        0x32fc95287b14eaef3afa92cccc48c285ee3a280a000100000000000000000005,
        qi,
        owner
      )
    );
    // QI-MIMATIC
    qi_powah = qi_powah.add(
      calculateBalancerPoolBalance(
        0x09804caea2400035b18e2173fdd10ec8b670ca0900020000000000000000000f,
        qi,
        owner
      )
    );

    return qi_powah;
  }

  function getAllCompounders(uint256 qi_powah, address owner) public view returns(uint256){

    // Adamant vaults
    qi_powah = qi_powah.add(
      calculateAddyPower(
        0x80506dBe1FE9DAbbD3F4D92Fc1CBA4866131bF82,
        0x7AfcF11F3e2f01e71B7Cc6b8B5e707E42e6Ea397,
        owner
      )
    );

    // Beefy
    // QI-MAI
    qi_powah = qi_powah.add(
      calculateBeefyPower(
        0xa2Dd60Fb8Bbf21e60E58AF97Cfc9dB9A34397848,
        0x7AfcF11F3e2f01e71B7Cc6b8B5e707E42e6Ea397,
        owner
      )
    );
    // QI-QUICK
    qi_powah = qi_powah.add(
      calculateBeefyPower(
        0x1d7A7182043F521ab57Fe07a8420Fee9843E365e,
        0x25d56E2416f20De1Efb1F18fd06dD12eFeC3D3D0,
        owner
      )
    );

    // Pickle jars
    // QI-MAI
    qi_powah = qi_powah.add(
      calculatePickleJarPower(
        0xd06a56c864C80e4cC76A2eF778183104BF0c848d,
        0x7AfcF11F3e2f01e71B7Cc6b8B5e707E42e6Ea397,
        owner
      )
    );

    // Pickle farms
    // p QI-MAI
    qi_powah = qi_powah.add(
      calculatePickleFarmPower(
        0x20B2a3fc7B13cA0cCf7AF81A68a14CB3116E8749,
        0xd06a56c864C80e4cC76A2eF778183104BF0c848d,
        0x7AfcF11F3e2f01e71B7Cc6b8B5e707E42e6Ea397,
        owner
      )
    );

    // QuickSwap staking pools
    // QI-QUICK
    qi_powah = qi_powah.add(
      calculateBalanceInQuickSwapStakingPool(
        0xad9E0d2FC293fD9a0f6c3C16c16A69d36B6D3b06,
        0x25d56E2416f20De1Efb1F18fd06dD12eFeC3D3D0,
        qi,
        owner
      )
    );

    // QI - WETH
    qi_powah = qi_powah.add(
      calculateBalanceInQuickSwapStakingPool(
        0xb47f7120a57381c217e4d6F3a79F066bfAAe6C93,
        0x8C1b40Ea78081B70F661C3286c74E71b4602C9C0,
        qi,
        owner
      )
    );
    return qi_powah;
  }

  IERC20 qix = IERC20(0xe1cA10e6a10c0F72B74dF6b7339912BaBfB1f8B5); // qix erc20
  IERC20 eqi = IERC20(0x880DeCADe22aD9c58A8A4202EF143c4F305100B3); // eqi erc20
  IPair QSpair = IPair(0x7AfcF11F3e2f01e71B7Cc6b8B5e707E42e6Ea397); // Qi-miMatic QS pair

  function balanceOf(address owner) public view returns (uint256) {
    IMasterChef chef = IMasterChef(
      0x574Fe4E8120C4Da1741b5Fd45584de7A5b521F0F
    ); // rewards contract

    // no xQi yet  IBar bar = IBar(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);

    uint256 qi_powah = qi.balanceOf(owner).add(qix.balanceOf(owner));

    uint256 lp_totalQi = qi.balanceOf(address(QSpair));
    uint256 lp_balance = QSpair.balanceOf(owner);

    // Add staked balance
    (uint256 lp_stakedBalance, ) = chef.userInfo(2, owner);
    lp_balance = lp_balance.add(lp_stakedBalance);

    uint256 lp_powah = 0;

    if (lp_balance > 0) {
      lp_powah = lp_totalQi.mul(lp_balance).div(QSpair.totalSupply());
      // all Qi in lp * user_lp_balance / total_lp_balance
    }

    (uint256 lp_stakedBalance4, ) = chef.userInfo(4, owner);

    IPair QSpair4 = IPair(0x9A8b2601760814019B7E6eE0052E25f1C623D1E6); // Qi-WMATIC QS pair
    uint256 lp_totalQi4 = qi.balanceOf(address(QSpair4));
    uint256 lp_balance4 = QSpair4.balanceOf(owner);

    if(lp_stakedBalance4 > 0) {
      lp_powah = lp_powah.add(lp_totalQi4.mul(lp_balance4).div(QSpair4.totalSupply()));
    }

    // add any unharvested Qi from the qi-mimatic staked pool
    qi_powah = qi_powah.add(chef.pending(0, owner));
    qi_powah = qi_powah.add(chef.pending(1, owner));
    qi_powah = qi_powah.add(chef.pending(2, owner));
    qi_powah = qi_powah.add(chef.pending(4, owner));

    // need to add nonincentivized farms as well

    qi_powah = getAllFarms(qi_powah, owner);

    // add eQi
    qi_powah = qi_powah.add(eqi.balanceOf(owner));

    qi_powah = getAllCompounders(qi_powah, owner);

    return lp_powah.add(qi_powah);
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}
