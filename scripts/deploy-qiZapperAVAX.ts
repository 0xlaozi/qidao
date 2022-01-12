import { ethers } from "hardhat";
async function main() {

    let zapperFactory = await ethers.getContractFactory("contracts\\beefyZapper.sol:beefyZapper");

    let zapper = await zapperFactory.deploy();
    console.log(zapper.address)
    console.log(zapper.deployTransaction.hash)
    await zapper.deployed();
    let zapChains =
        [
            {
                //MooAaveAVAX
                receiptToken: "0x1B156C5c75E9dF4CAAb2a5cc5999aC58ff4F9090",
                underlying: "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7",
                vault: "0xfA19c1d104F4AEfb8d5564f02B3AdCa1b515da58"
            }
        ]

    for(let chain of zapChains){
        await zapper.addChainToWhiteList(chain.underlying , chain.receiptToken, chain.vault);
        console.log(`Added whitelist for ${chain.vault}`);
    }
    console.log("Done!");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
