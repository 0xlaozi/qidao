import { ethers, run } from "hardhat";
async function main() {
    let zapperFactory = await ethers.getContractFactory("contracts\\camZapper.sol:camZapper");

    console.log(`Deploying camZapper...`)
    let zapper = await zapperFactory.deploy();
    await zapper.deployed();
    console.log(`Zapper deploy at ${zapper.address}`)
    console.log(`in TX ${zapper.deployTransaction.hash}`)

    console.log(`Verifying camZapper...`)
    await run("verify:verify", {
        address: zapper.address,
    });

    let zapChains = [
        {
            //camWMATIC
            asset: "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270",
            amAsset: "0x8df3aad3a84da6b69a4da8aec3ea40d9091b2ac4",
            camAsset: "0x7068ea5255cb05931efa8026bd04b18f3deb8b0b",
            camAssetVault: "0x88d84a85a87ed12b8f098e8953b322ff789fcd1a"
        },
        {
            //camWBTC
            asset: "0x1bfd67037b42cf73acf2047067bd4f2c47d9bfd6",
            amAsset: "0x5c2ed810328349100a66b82b78a1791b101c9d61",
            camAsset: "0xba6273a78a23169e01317bd0f6338547f869e8df",
            camAssetVault: "0x7dda5e1a389e0c1892caf55940f5fce6588a9ae0"
        },
        {
            //camAAVE
            asset: "0xd6df932a45c0f255f85145f286ea0b292b21c90b",
            amAsset: "0x1d2a0e5ec8e5bbdca5cb219e649b565d8e5c3360",
            camAsset: "0xea4040b21cb68afb94889cb60834b13427cfc4eb",
            camAssetVault: "0x578375c3af7d61586c2c3a7ba87d2eed640efa40"
        },
        {
            //camWETH
            asset: "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
            amAsset: "0x28424507fefb6f7f8e9d3860f56504e4e5f5f390",
            camAsset: "0x0470cd31c8fcc42671465880ba81d631f0b76c1d",
            camAssetVault: "0x11a33631a5b5349af3f165d2b7901a4d67e561ad"
        },
        {
            //camDAI
            asset: "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063",
            amAsset: "0x27f8d03b3a2196956ed754badc28d73be8830a6e",
            camAsset: "0xe6c23289ba5a9f0ef31b8eb36241d5c800889b7b",
            camAssetVault: "0xd2fe44055b5c874fee029119f70336447c8e8827"
        },
    ]
    console.log(`Adding whitelisted assets`)
    let tx;
    for (let chain of zapChains) {
        tx = await zapper.addChainToWhiteList(chain.asset, chain.amAsset, chain.camAsset, chain.camAssetVault);
        tx.wait(1);
        console.log(`Added whitelist for ${chain.asset}`);
    }
    console.log("Done!");
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
