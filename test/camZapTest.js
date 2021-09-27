const { ethers } = require("hardhat");
const {assert} = require("chai");

describe("My Dapp", function () {
    describe("YourContract", function () {
        it("Should Zap the funds into the Vault", async function () {

            const camTokenFactory = await ethers.getContractFactory("contracts\\camToken.sol:camToken")
            const camZapperFactory  = await ethers.getContractFactory("contracts\\camZapper.sol:camZapper");
            const erc20Factory = await ethers.getContractFactory("contracts\\simpleErc20.sol:simpleErc20")
            const erc20StablecoinVaultFactory = await ethers.getContractFactory("erc20Stablecoin");
            const priceSource = await ethers.getContractAt("PriceSource", "0x0fda41a1d4555b85021312b765c6d519b9c66f93");


            let camWETHInfo = {
                amToken:"0x28424507fefb6f7f8e9d3860f56504e4e5f5f390",
                camToken: "0x0470CD31C8FcC42671465880BA81D631F0B76C1D",
                decimals: "18",
                name: "Compounding Aave Market WETH",
                symbol: "camWETH",
                underlying: "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
            }

            const camToken  = await camTokenFactory.attach(camWETHInfo.camToken);
            const amToken = await erc20Factory.attach(camWETHInfo.amToken);
            const token = await erc20Factory.attach(camWETHInfo.underlying);
            const zapper = await camZapperFactory.deploy();

            const mimatic = await erc20Factory.deploy(
              "10000000000000000000000000",
              "miMatic",
              "miMatic",
              18
            );

            //Vault based on https://polygonscan.com/address/0x11A33631a5B5349AF3F165d2B7901A4d67e561ad
            const vault = await erc20StablecoinVaultFactory.deploy(
              priceSource.address,
              135,
              "camToken MAI Vault ",
              "camTKNVT",
              mimatic.address,
              camToken.address,
              "0x4920184F60221a75Abf39BB0b4D06ac25D9b2bb2", //VaultMetaRegistry
              "" //BaseUri, which is empty in deployed code
            )
            let wethAccountAddress = "0x6cc12f719081bc13d50029b6E18E7464B14d467c"
            await ethers.provider.send('hardhat_impersonateAccount', [wethAccountAddress])
            const wethAccountSigner = await ethers.getSigner(wethAccountAddress);

            const accounts = await ethers.getSigners();
            const deployerAccount = accounts[0];

            let wethHolderTokenContract = token.connect(wethAccountSigner);
            let wethHolderBalance = await wethHolderTokenContract.balanceOf(wethAccountSigner.address);
            await wethHolderTokenContract.transfer(deployerAccount.address, wethHolderBalance)

            let preZapTokenBal = await token.balanceOf(deployerAccount.address);
            await token.approve(zapper.address, preZapTokenBal);
            await zapper.camZapToVault(preZapTokenBal, 0, token.address, amToken.address, camToken.address, vault.address);

            let postZapTokenBal = ethers.utils.formatUnits(await token.balanceOf(deployerAccount.address))
            let vaultIdx = await vault.tokenOfOwnerByIndex(deployerAccount.address,0);
            let vaultColat = parseFloat(ethers.utils.formatUnits(await vault.vaultCollateral(vaultIdx)));

            assert.approximately(vaultColat,
              parseFloat(ethers.utils.formatUnits(preZapTokenBal)) * 0.995,
              0.01,
              "vault collateral should be about 95% of the deposited balance");
            assert.equal(parseFloat(postZapTokenBal), 0, "sender token balance should be 0 after zapping")
        }).timeout(1000000);
    })
});
