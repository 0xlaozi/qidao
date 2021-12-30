const {ethers} = require("hardhat");
const chai = require("chai");
const {assert, expect} = require("chai");
const {setStorageAt, toBytes32} = require("./storageManipulation/storageManipulation");
chai.use(require('chai-as-promised'))

async function modifyTokenBalanceOf(tokenAddress, tokenSlot, addressToSetBalOn, balanceToSet) {
  // Get storage slot index
  const index = ethers.utils.solidityKeccak256(
    ["uint256", "uint256"],
    [addressToSetBalOn, tokenSlot] // key, slot
  );

  // Manipulate local balance (needs to be bytes32 string)
  await setStorageAt(
    tokenAddress,
    index.toString(),
    toBytes32(ethers.BigNumber.from(balanceToSet)).toString()
  );
}

describe("Zap Test", function () {
  describe("Beefy", function () {
    let camZapperFactory, erc20Factory, erc20StablecoinVaultFactory, priceSource;

    it("Should setup required contract factories", async () => {
      camZapperFactory = await ethers.getContractFactory("contracts\\beefyZapper.sol:beefyZapper");
      erc20Factory = await ethers.getContractFactory("contracts\\simpleErc20.sol:simpleErc20")
      erc20StablecoinVaultFactory = await ethers.getContractFactory("crosschainStablecoin");
      priceSource = await ethers.getContractAt("PriceSource", "0x0fda41a1d4555b85021312b765c6d519b9c66f93");

    });

    let link, mooScreamToken, mimatic, vault, zapper,
      beefyLinkInfo = {
          mooScreamToken: "0x6dfe2aaea9daadadf0865b661b53040e842640f8",
          decimals: "18",
          name: "Moo Scream LINK",
          symbol: "mooScreamLink",
          underlying: "0xb3654dc3d10ea7645f8319668e8f54d2574fbdc8",
          underlyingBalSlot: 2,
      };

    it("should setup the camToken chain, zapper, MAI, and vault", async () => {
      mimatic = await erc20Factory.deploy(
        "10000000000000000000000000",
        "miMatic",
        "miMatic",
        18
      );
      link = await erc20Factory.attach(beefyLinkInfo.underlying);
      mooScreamToken = await erc20Factory.attach(beefyLinkInfo.mooScreamToken);
      zapper = await camZapperFactory.deploy();

      //Vault based on https://polygonscan.com/address/0x11A33631a5B5349AF3F165d2B7901A4d67e561ad
      vault = await erc20StablecoinVaultFactory.deploy(
        priceSource.address,
        135,
        "mooScream MAI Vault ",
        "mooScreamTKNVT",
        mimatic.address,
        mooScreamToken.address,
        "" //BaseUri, which is empty in deployed code
      )
      await zapper.addChainToWhiteList(link.address, mooScreamToken.address, vault.address)
    })

    let  deployerAccount;
    it('Should impersonate the weth holder account and fetch deployer account', async () => {
      deployerAccount = (await ethers.getSigners())[0];
      await modifyTokenBalanceOf(link.address, beefyLinkInfo.underlyingBalSlot, deployerAccount.address, 10000)
    });

    let preZapTokenBal;

    it("Should approve the zapper contract to zap weth", async () => {
      preZapTokenBal = await link.balanceOf(deployerAccount.address);
      await link.approve(zapper.address, preZapTokenBal);
    })

    it("Should Zap the funds into the Vault", async function () {

      const zapAmount = preZapTokenBal.div(2);
      await vault.createVault();
      await zapper.beefyZapToVault(zapAmount, 0, link.address, mooScreamToken.address, vault.address);

      let postZapTokenBal = ethers.utils.formatUnits(await link.balanceOf(deployerAccount.address))
      let vaultIdx = await vault.tokenOfOwnerByIndex(deployerAccount.address, 0);
      let vaultColat = parseFloat(ethers.utils.formatUnits(await vault.vaultCollateral(vaultIdx)));

      assert.approximately(vaultColat,
        parseFloat(ethers.utils.formatUnits(zapAmount)) * 0.995,
        4000,
        "vault collateral should be about 99.5% of the deposited balance");
      assert.equal(parseFloat(postZapTokenBal), ethers.utils.formatUnits(zapAmount), "sender token balance should be 0 after zapping")
    }).timeout(100_000);

    it("Should fail to zap into a vault that doesn't exist", async () => {
      await expect(zapper.beefyZapToVault(preZapTokenBal, 1, link.address, mooScreamToken.address, vault.address))
        .to.be.rejectedWith(Error);
    }).timeout(100_000);

  }).timeout(1000000);

  describe("Yearn", function () {
    let zapperFactory, erc20Factory, erc20StablecoinVaultFactory, priceSource;

    it("Should setup required contract factories", async () => {
      zapperFactory = await ethers.getContractFactory("contracts\\beefyZapper.sol:beefyZapper");
      erc20Factory = await ethers.getContractFactory("contracts\\simpleErc20.sol:simpleErc20")
      erc20StablecoinVaultFactory = await ethers.getContractFactory("crosschainStablecoin");
      priceSource = await ethers.getContractAt("PriceSource", "0x0fda41a1d4555b85021312b765c6d519b9c66f93");

    });

    let WFTM, yvToken, mimatic, vault, zapper,
      yearnWFTMInfo = {
        yvToken: "0x0DEC85e74A92c52b7F708c4B10207D9560CEFaf0",
        decimals: "18",
        name: "WFTM yVault",
        symbol: "yvWFTM",
        underlying: "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83",
        underlyingBalSlot: 0,
      };

    it("should setup the camToken chain, zapper, MAI, and vault", async () => {
      mimatic = await erc20Factory.deploy(
        "10000000000000000000000000",
        "miMatic",
        "miMatic",
        18
      );
      WFTM = await erc20Factory.attach(yearnWFTMInfo.underlying);
      yvToken = await erc20Factory.attach(yearnWFTMInfo.yvToken);
      zapper = await zapperFactory.deploy();

      //Vault based on https://polygonscan.com/address/0x11A33631a5B5349AF3F165d2B7901A4d67e561ad
      vault = await erc20StablecoinVaultFactory.deploy(
        priceSource.address,
        135,
        "yvToken MAI Vault ",
        "yvTKNVT",
        mimatic.address,
        yvToken.address,
        "" //BaseUri, which is empty in deployed code
      )
      await zapper.addChainToWhiteList(WFTM.address, yvToken.address, vault.address)
    })

    let  deployerAccount;
    it('Should impersonate the weth holder account and fetch deployer account', async () => {
      deployerAccount = (await ethers.getSigners())[0];
      await modifyTokenBalanceOf(WFTM.address, yearnWFTMInfo.underlyingBalSlot, deployerAccount.address, 10000)
    });

    let preZapTokenBal;

    it("Should approve the zapper contract to zap weth", async () => {
      preZapTokenBal = await WFTM.balanceOf(deployerAccount.address);
      await WFTM.approve(zapper.address, preZapTokenBal);
    })

    it("Should Zap the funds into the Vault", async function () {

      const zapAmount = preZapTokenBal.div(2);
      await vault.createVault();
      await zapper.beefyZapToVault(zapAmount, 0, WFTM.address, yvToken.address, vault.address);

      let postZapTokenBal = ethers.utils.formatUnits(await WFTM.balanceOf(deployerAccount.address))
      let vaultIdx = await vault.tokenOfOwnerByIndex(deployerAccount.address, 0);
      let vaultColat = parseFloat(ethers.utils.formatUnits(await vault.vaultCollateral(vaultIdx)));

      assert.approximately(vaultColat,
        parseFloat(ethers.utils.formatUnits(zapAmount)) * 0.995,
        4000,
        "vault collateral should be about 99.5% of the deposited balance");
      assert.equal(parseFloat(postZapTokenBal), ethers.utils.formatUnits(zapAmount), "sender token balance should be 0 after zapping")
    }).timeout(100_000);

    it("Should fail to zap into a vault that doesn't exist", async () => {
      await expect(zapper.beefyZapToVault(preZapTokenBal, 1, WFTM.address, yvToken.address, vault.address))
        .to.be.rejectedWith(Error);
    }).timeout(100_000);

  }).timeout(1000000);
});
