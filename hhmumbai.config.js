let hhconfig = require('./hardhat.config.js');
require("@nomicfoundation/hardhat-toolbox");
require('hardhat-deploy');
let constants = require('./scripts/constants.js');

// npx hardhat node --fork https://rpc-mumbai.maticvigil.com/ --port 4545 --config hhmumbai.config.js
hhconfig.networks.hardhat.chainId = 3777
hhconfig.networks.hardhat.name = 'hhmumbai'

hhconfig.networks.hhmumbai = {
  name: 'hhmumbai',
  url: `http://localhost:4545`,
  accounts: constants.prvKeysList,
  gasLimit: 6000000000,
  defaultBalanceEther: 10,
  chainId: 3777
}

//console.log(hhconfig)
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = hhconfig;