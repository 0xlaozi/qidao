import { ethers } from "hardhat";
async function main() {
  const factory = await ethers.getContractFactory("QiStablecoin");
  
  const miMatic = await factory.attach("0x5e84E7a14b9313901e6Cd9244a7AAdF812dF2a98")

  await miMatic.setDebtCeiling("100000000000000000000000");
  
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });