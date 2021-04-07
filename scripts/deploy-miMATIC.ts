import { ethers } from "hardhat";
async function main() {
  const factory = await ethers.getContractFactory("QiStablecoin");
  // If we had constructor arguments, they would be passed into deploy()
  let contract = await factory.deploy(
            "0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada",
            150,
            'miMATIC',
            'miMATIC');
  // The address the Contract WILL have once mined
  console.log(contract.address);
  // The transaction that was sent to the network to deploy the Contract
  console.log(contract.deployTransaction.hash);
  // The contract is NOT deployed yet; we must wait until it is mined
  await contract.deployed();

  // then set the oracle for price
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });