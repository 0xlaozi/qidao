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
                //MooScreamLink
                receiptToken: "0x6dfe2aaea9daadadf0865b661b53040e842640f8",
                underlying: "0xb3654dc3d10ea7645f8319668e8f54d2574fbdc8",
                vault: "0x8e5e4D08485673770Ab372c05f95081BE0636Fa2"
            },
            {
                //MooScreamFTM
                receiptToken: "0x49c68edb7aebd968f197121453e41b8704acde0c",
                underlying: "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83",
                vault: "0x3609A304c6A41d87E895b9c1fd18c02ba989Ba90"
            },
            {
                //MooScreamWBTC
                receiptToken: "0x97927abfe1abbe5429cbe79260b290222fc9fbba",
                underlying: "0x321162cd933e2be498cd2267a90534a804051b11",
                vault: "0x5563Cc1ee23c4b17C861418cFF16641D46E12436"
            },
            {
                //MooScreamDAI
                receiptToken: "0x920786cff2a6f601975874bb24c63f0115df7dc8",
                underlying: "0x8d11ec38a3eb5e956b052f67da8bdc9bef8abf3e",
                vault: "0xBf0ff8ac03f3E0DD7d8faA9b571ebA999a854146"
            },
            {
                //MooScreamETH
                receiptToken: "0x0a03d2c1cfca48075992d810cc69bd9fe026384a",
                underlying: "0x74b23882a30290451a17c44f4f05243b6b58c76d",
                vault: "0xC1c7eF18ABC94013F6c58C6CdF9e829A48075b4e"
            },
            {
                //YearnWFTM
                receiptToken: "0x0DEC85e74A92c52b7F708c4B10207D9560CEFaf0",
                underlying: "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83",
                vault: "0x7efB260662a6FA95c1CE1092c53Ca23733202798"
            },
            {
                //YearnDAI
                receiptToken: "0x637ec617c86d24e421328e6caea1d92114892439",
                underlying: "0x8d11ec38a3eb5e956b052f67da8bdc9bef8abf3e",
                vault: "0x682E473FcA490B0adFA7EfE94083C1E63f28F034"
            },
        ]

    for(let chain of zapChains){
        await zapper.addChainToWhiteList(chain.underlying , chain.receiptToken, chain.vault);
        console.log(`Added whitelist for ${chain.vault}`);
    }
    console.log("Done!");

    // console.log(qiStablecoin.address);
    // // The transaction that was sent to the network to deploy the Contract
    // console.log(qiStablecoin.deployTransaction.hash);
    // // The contract is NOT deployed yet; we must wait until it is mined
    // await qiStablecoin.deployed();
  // const vault = await ethers.getContractFactory("VaultNFT");
  //
  // let vaultContract = await vault.deploy();
  //
  // // If we had constructor arguments, they would be passed into deploy()
  // let qiStablecoin = await qiStablecoinFactory.deploy(
  //           "0xAB594600376Ec9fD91F8e885dADF0CE036862dE0", // mainnet 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
  //           150,                                          // mumbai 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
  //           'miMATIC',
  //           'miMATIC',
  //           vaultContract.address
  //           );
  // // The address the Contract WILL have once mined
  // console.log(qiStablecoin.address);
  // // The transaction that was sent to the network to deploy the Contract
  // console.log(qiStablecoin.deployTransaction.hash);
  // // The contract is NOT deployed yet; we must wait until it is mined
  // await qiStablecoin.deployed();
  //
  // await vaultContract.setAdmin(qiStablecoin.address);
  //
  // const firstOwner = await qiStablecoin.owner();
  //
  // console.log("owner", firstOwner);
  //
  // console.log("transferring ownership to the Ledger wallet.");
  //
  // await qiStablecoin.transferOwnership("0x86fE8d6D4C8A007353617587988552B6921514Cb")
  //
  // const secondOwner = await qiStablecoin.owner();
  // console.log(secondOwner);
  // // mainnet v1 mimatic = 0xa3Fa99A148fA48D14Ed51d610c367C61876997F1
  // // mainnet MMVT = 0x6AF1d9376a7060488558cfB443939eD67Bb9b48d
  // // then set the oracle for price
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
