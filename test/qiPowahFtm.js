const { ethers } = require("hardhat");
const chai  = require("chai");
const {assert, expect}  = require("chai");
chai.use(require('chai-as-promised'))

const toBytes32 = (bn) => {
  return ethers.utils.hexlify(ethers.utils.zeroPad(bn.toHexString(), 32));
};

const setStorageAt = async (address, index, value) => {
  await ethers.provider.send("hardhat_setStorageAt", [address, index, value]);
  await ethers.provider.send("evm_mine", []); // Just mines to the next block
};


describe("FTM Dapp", function () {
  describe("QI Powah FTM", function () {
    let qiPowahFtmContractFactory;

    it("Should setup required contract factories", async () => {
      qiPowahFtmContractFactory = await ethers.getContractFactory("contracts/QiPowahFTM.sol:QIPOWAHFTM")
    });

    let emptyAccountAddress = "0x6cc12f719081bc13d50029b6E18E7464B14d467c";

    let accountAddressWithQi = "0x20dd72ed959b6147912c2e529f0a0c651c33c9ce";
    let slotForQiOnAddressWithQI = 0;

    let accountAddressWithRewardsStaking = "0xe32650e748e7e4aba16181d9882d15ba328d5a78";
    let slotForAddressWithRewardsStaking = 0;

    let accountAddressWithBeetsPool = "0x679016b3f8e98673f85c6f72567f22b58aa15a54";
    let slotForAddressWithBeetsPool = 0;

    let rewardsStakingAddress = "0x230917f8a262bF9f2C3959eC495b11D1B7E1aFfC";
    let qiAddress = "0x68Aa691a8819B07988B18923F712F3f4C8d36346";
    let beetsPoolAddress = "0x7aE6A223cde3A17E0B95626ef71A2DB5F03F540A";

    it("should deploy the contract and check an address with an empty balance without issue", async () =>{
      const powahContract = await qiPowahFtmContractFactory.deploy();
      const txn = await powahContract.balanceOf(emptyAccountAddress);
      assert.equal(0, txn, "address qi powah should be 0");
    })

    it("should deploy the contract and check an address with an non-empty balance without issue", async () =>{
      const powahContract = await qiPowahFtmContractFactory.deploy();
      const locallyManipulatedBalance = ethers.utils.parseUnits("100000");
      // Get storage slot index
      const index = ethers.utils.solidityKeccak256(
        ["uint256", "uint256"],
        [accountAddressWithQi, slotForQiOnAddressWithQI] // key, slot
      );

      // Manipulate local balance (needs to be bytes32 string)
      await setStorageAt(
        qiAddress,
        index.toString(),
        toBytes32(locallyManipulatedBalance).toString()
      );
      const txn = await powahContract.balanceOf(accountAddressWithQi);
      assert.equal(100000000000000000000000, txn, "address qi powah should be 100000000000000000000000")
    })

    it("should deploy the contract and check an address with reward staking", async () =>{
      const powahContract = await qiPowahFtmContractFactory.deploy();
      const txn = await powahContract.balanceOf(accountAddressWithRewardsStaking);
      assert.equal(314338521461776300, txn.toNumber(), "address qi powah should be 314338521461776300")
    })

    it("should deploy the contract and check an address with assets in the beets pool", async () =>{
      const powahContract = await qiPowahFtmContractFactory.deploy();
      const locallyManipulatedBalance = ethers.utils.parseUnits("100000");
      // Get storage slot index
      const index = ethers.utils.solidityKeccak256(
        ["uint256", "uint256"],
        [accountAddressWithBeetsPool, slotForAddressWithBeetsPool] // key, slot
      );

      await setStorageAt(
        qiAddress,
        index.toString(),
        toBytes32(ethers.utils.parseUnits("0")).toString()
      );

      // Manipulate local balance (needs to be bytes32 string)
      await setStorageAt(
        beetsPoolAddress,
        index.toString(),
        toBytes32(locallyManipulatedBalance).toString()
      );
      const txn = await powahContract.balanceOf(accountAddressWithBeetsPool);
      assert(txn.gte(ethers.utils.parseEther("1")),
        "address qi powah should be greater than 1000000000000000000")
    })

  }).timeout(1000000);
});
