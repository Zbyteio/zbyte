let hhconfig = require('./hardhat.config.js');
require("@nomicfoundation/hardhat-toolbox");
require('hardhat-deploy');
let constants = require('./scripts/constants.js');

// npx hardhat node --fork https://api.avax-test.network/ext/bc/C/rpc --port 3545 --config hhfuji.config.js
hhconfig.networks.hardhat.chainId = 3776
hhconfig.networks.hardhat.name = 'hhfuji'
hhconfig.networks.hhfuji =  {
  name: 'hhfuji',
  url: `http://localhost:3545`,
  accounts: constants.prvKeysList,
  gasLimit: 6000000000,
  defaultBalanceEther: 10,
  chainId: 3776
},

//console.log(hhconfig)
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = hhconfig;