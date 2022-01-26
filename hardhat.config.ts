require('dotenv').config()

import {HardhatUserConfig} from "hardhat/types";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-typechain";

let privateKey = process.env.PRIVATE_KEY;

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: {
    compilers: [{ version: "0.5.5", settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    }
  },{ version: "0.5.16", settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    }
  },{ version: "0.6.12", settings: {
        optimizer: {
          enabled: true,
          runs: 1000
        }
      }
    },{ version: "0.7.6", settings: {
        optimizer: {
          enabled: true,
          runs: 1000
        }
      }
    },{ version: "0.8.0", settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    }
  }],
  },
  networks: {
    hardhat: {
      forking: {
        enabled: true,
        url: `https://polygon-mainnet.infura.io/v3/${process.env.POLYGON_INFURA_KEY}`
      },
    },
    polygon:{
      chainId: 137,
      url: `https://polygon-mainnet.infura.io/v3/${process.env.POLYGON_INFURA_KEY}`,
      accounts: [`0x${privateKey}`],
    },
    avax: {
      chainId: 43114,
      url: `https://api.avax.network/ext/bc/C/rpc`,
      accounts: [`0x${privateKey}`],
    },
    fantom: {
      chainId: 250,
      url: `https://rpc.ftm.tools/`,
      accounts: [`0x${privateKey}`],
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey:{
      mainnet: process.env.ETHERSCAN_KEY,
      ropsten: process.env.ETHERSCAN_KEY,
      rinkeby: process.env.ETHERSCAN_KEY,
      goerli: process.env.ETHERSCAN_KEY,
      kovan: process.env.ETHERSCAN_KEY,
      // binance smart chain
      bsc: process.env.BSCSCAN_KEY,
      bscTestnet: process.env.BSCSCAN_KEY,
      // huobi eco chain
      heco: process.env.HECOINFO_KEY,
      hecoTestnet: process.env.HECOINFO_KEY,
      // fantom mainnet
      opera: process.env.FTMSCAN_KEY,
      ftmTestnet: process.env.FTMSCAN_KEY,
      // optimism
      optimisticEthereum: process.env.OPTIMISTIC_ETHERSCAN_KEY,
      optimisticKovan: process.env.OPTIMISTIC_ETHERSCAN_KEY,
      // polygon
      polygon: process.env.POLYGONSCAN_KEY,
      polygonMumbai: process.env.POLYGONSCAN_KEY,
      // arbitrum
      arbitrumOne: process.env.ARBISCAN_KEY,
      arbitrumTestnet: process.env.ARBISCAN_KEY,
      // avalanche
      avalanche: process.env.SNOWTRACE_KEY,
      avalancheFujiTestnet: process.env.SNOWTRACE_KEY,
      // moonriver
      moonriver: process.env.MOONRIVER_MOONSCAN_KEY,
      moonbaseAlpha: process.env.MOONRIVER_MOONSCAN_KEY,
      // xdai and sokol don't need an API key, but you still need
      // to specify one; any string placeholder will work
      xdai: "api-key",
      sokol: "api-key",
    }
  },
};
export default config;
