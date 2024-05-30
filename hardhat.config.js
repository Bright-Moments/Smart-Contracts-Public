require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("dotenv/config");
require("hardhat-gas-reporter");

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 10000,
      },
    },
  },
  mocha: {
    timeout: 100000000
  },
  defaultNetwork: "hardhat",
  networks: { 
    hardhat: {},
    mainnet: {
      url: `${process.env.INFURA_MAINNET_URL}`,
      accounts: [process.env.PRIVATE_KEY_DEPLOYER]
    },
    polygon: {
      url: `${process.env.POLYGON_URL}`,
      accounts: [process.env.PRIVATE_KEY_DEPLOYER]
    },
    avax: {
      url: `${process.env.INFURA_AVAX_URL}`,
      accounts: [process.env.PRIVATE_KEY_DEPLOYER]
    },
    rinkeby: {
      url: `${process.env.INFURA_RINKEBY_URL}`,
      accounts: [process.env.PRIVATE_KEY_TESTING]
    },
    ropsten: {
      url: `${process.env.INFURA_ROPSTEN_URL}`,
      accounts: [process.env.PRIVATE_KEY_TESTING]
    },
    kovan: {
      url: `${process.env.INFURA_KOVAN_URL}`,
      accounts: [process.env.PRIVATE_KEY_TESTING]
    },
    sepolia: {
      url: `${process.env.INFURA_SEPOLIA_URL}`,
      accounts: [process.env.PRIVATE_KEY_TESTING],
      chainId: 11155111
    },
    mumbai: {
      url: `${process.env.MUMBAI_URL}`,
      accounts: [process.env.PRIVATE_KEY_TESTING]
    },
    fuji: {
      url: `${process.env.INFURA_FUJI_URL}`,
      accounts: [process.env.PRIVATE_KEY_TESTING],
      chainId: 43113
    },
    goerli: {
      url: `${process.env.INFURA_GOERLI_URL}`,
      accounts: [process.env.PRIVATE_KEY_TESTING],
      chainId: 5
    },
    mainnetminter: {
      url: `${process.env.INFURA_MAINNET_URL}`,
      accounts: [process.env.PRIVATE_KEY_MINTER],
      chainId: 0
    },
    base: {
      url: `${process.env.INFURA_BASE_URL}`,
      accounts: [process.env.PRIVATE_KEY_DEPLOYER],
      chainId: 8453
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  etherscan: {
    apiKey: {
      avalancheFujiTestnet: `${process.env.API_KEY_AVAX}`, // AVAX FUJI TESTNET
      avalanche: `${process.env.API_KEY_AVAX}`, // AVAX MAINNET
      mainnet: `${process.env.API_KEY_ETHERSCAN}`, // ETH MAINNET
      polygon: `${process.env.API_KEY_POLYGON}`, // POLYGON MAINNET
      sepolia: `${process.env.API_KEY_ETHERSCAN}`, // SEPOLIA TESTNET
      base: `${process.env.API_KEY_BASE}`, // BASE MAINNET
    },
    customChains: [
      {
        network: "base",
        chainId: 8453,
        urls: {
          apiURL: "https://api.basescan.org/api",
          browserURL: "https://basescan.org/"
        }
      }
    ],
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
    gasPrice: 70,
    coinmarketcap: `${process.env.API_KEY_COINMARKETCAP}`,
    onlyCalledMethods: true,
    showTimeSpent: true,
  }
};
