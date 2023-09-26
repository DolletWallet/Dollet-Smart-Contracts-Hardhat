import { HardhatUserConfig } from "hardhat/config";

import "@nomicfoundation/hardhat-toolbox";

import "@openzeppelin/hardhat-upgrades";

import "@nomiclabs/hardhat-etherscan";

import "hardhat-dependency-compiler";

import "@nomiclabs/hardhat-ethers";

import * as dotenv from "dotenv";

import "solidity-coverage";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.10",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000,
          },
        },
      },
    ],
  },

  defaultNetwork: "hardhat",
  networks: {
    goerli: {
      url: `${process.env.ETHEREUM_GOERLI_RPC}`,
      chainId: 5,
      accounts: [(process.env.PRIVATE_KEY || "").trim()],
      timeout: 86400000,
      gasPrice: 2000000000, // 2 Gwei
    },
    mainnet: {
      url: `${process.env.ETHEREUM_MAINNET_RPC}`,
      accounts: [process.env.PRIVATE_KEY || ""],
      chainId: 1,
      gasPrice: 15000000000, // 15 Gwei
    },
    arbitrum: {
      url: `${process.env.ARBITRUM_MAINNET_RPC}`,
      accounts: [process.env.PRIVATE_KEY || ""],
      chainId: 42161,
      gasPrice: 100000000, // 0.1 Gwei
    },
  },

  etherscan: {
    apiKey: {
      mainnet: (process.env.ETHERSCAN_API_KEY || "").trim(),
      goerli: (process.env.ETHERSCAN_API_KEY || "").trim(),
      arbitrumOne: (process.env.ARBISCAN_API_KEY || "").trim(),
    },
  },

  dependencyCompiler: {
    paths: ["@openzeppelin/contracts/governance/TimelockController.sol"],
  },

  mocha: {
    timeout: 100_000_000,
  },
};

export default config;
