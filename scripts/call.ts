import { ethers } from "hardhat";
async function main() {
  const factory = await ethers.getContractFactory("QiStablecoin");
  
  const miMatic = await factory.attach("0x5d0918Bd4F9CD4f142ccF1dFb165530b4ce48433");
  
  const secondOwner = await miMatic.owner(); 
  console.log(secondOwner);    
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });