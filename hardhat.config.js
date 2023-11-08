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
    }
  }
};
