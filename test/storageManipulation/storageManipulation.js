const {ethers} = require("hardhat");

function toBytes32(bn) {
  return ethers.utils.hexlify(ethers.utils.zeroPad(bn.toHexString(), 32));
}

async function setStorageAt(address, index, value) {
  await ethers.provider.send("hardhat_setStorageAt", [address, index, value]);
  await ethers.provider.send("evm_mine", []); // Just mines to the next block
}

module.exports = {
  toBytes32, setStorageAt
};
