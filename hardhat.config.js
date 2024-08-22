require("@nomicfoundation/hardhat-toolbox");
require('solidity-docgen');
require('hardhat-deploy');
require('./tasks/tasks.js')
let constants = require('./scripts/constants.js');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  docgen: {
    path: './docs',
    clear: true,
    runOnCompile: true,
  },
  networks: {
    fuji: {
      url: `https://api.avax-test.network/ext/bc/C/rpc`,
      accounts: constants.prvKeysList,
      chainId: 43113
    },
    mumbai: {
      url: `https://rpc-mumbai.maticvigil.com/`,
      accounts: constants.prvKeysList,
      chainId: 80001
    },
    hardhat: {  // npx hardhat node
      accounts: {
        mnemonic: process.env.MNEMONIC,
        count: 15
     }
    },
    polygon: {
      url: `https://polygon-mainnet.infura.io/v3/c4adc113c65d419fa4aa11d536d51e2c`,
      accounts: constants.prvKeysList,
      chainId: 137
    },
    amoy: {
      url: `https://polygon-amoy.infura.io/v3/c4adc113c65d419fa4aa11d536d51e2c`,
      accounts: constants.prvKeysList,
      chainId: 80002
    },
    avalanche: {
      url: `https://avalanche-mainnet.infura.io/v3/c4adc113c65d419fa4aa11d536d51e2c`,
      accounts: constants.prvKeysList,
      chainId: 43114
    },
    hederatest: {
      url: `https://testnet.hashio.io/api`,
      accounts: constants.prvKeysList,
      chainId: 296
    },
    basetest: {
      url: `https://sepolia.base.org`,
      accounts: constants.prvKeysList,
      chainId: 84532
    },
    hedera: {
      url: `https://twilight-attentive-card.hedera-mainnet.quiknode.pro/13f50a5e488608f538c2b0143bed06658f6f5fdb/`,
      //url: `https://mainnet.hedera.validationcloud.io/v1/cT55tYBL7gZhJtA3TdxkrVO4DKzkJ0t6n1_CerxS8HI`,
      accounts: constants.prvKeysList,
      chainId: 295,
      timeout: 100_000,
    },
    base: {
      url: `https://base.llamarpc.com`,
      accounts: constants.prvKeysList,
      chainId: 8453,
      time_out: 100_000,
    }
  }
};
