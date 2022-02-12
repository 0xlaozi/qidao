import {ethers, run} from "hardhat";
async function main() {

    let zapperFactory = await ethers.getContractFactory("contracts\\beefyZapper.sol:beefyZapper");

    console.log(`Deploying ftmZapper...`)
    let zapper = await zapperFactory.deploy();
    // let zapper = zapperFactory.attach("0xE2379CB4c4627E5e9dF459Ce08c2342C696C4c1f")
    await zapper.deployed();
    console.log(`Zapper deploy at ${zapper.address}`)
    console.log(`in TX ${zapper.deployTransaction.hash}`)
    console.log(`Verifying ftmZapper...`)
    try{
        await run("verify:verify", {
            address: zapper.address,
        });
    } catch (e) {
        console.warn(e);
    }

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
                //MooFantomBIFI
                receiptToken: "0xbF07093ccd6adFC3dEB259C557b61E94c1F66945",
                underlying: "0xd6070ae98b8069de6B494332d1A1a81B6179D960",
                vault: "0x75D4aB6843593C111Eeb02Ff07055009c836A1EF"
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

    let tx;
    for (let chain of zapChains) {
        tx = await zapper.addChainToWhiteList(chain.underlying, chain.receiptToken, chain.vault);
        tx.wait(20);
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
