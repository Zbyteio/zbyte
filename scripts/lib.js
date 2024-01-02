const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");
const constants = require("./constants.js")

function isCoreChain() {
    return hre.network.name == process.env.CORE;
}

function isDplatChain() {
    return hre.network.name == process.env.DPLAT;
}

function getPrvKey(user) {
    return constants.privateKeys[user];
}

async function getL1Balance(user) {
    let userAddr = await getAddress(user);
    let provider = ethers.provider;
    return await provider.getBalance(userAddr);
}

async function transferL1(sender,receiver) {
    let privateKey = getPrvKey(sender);
    let wallet = new ethers.Wallet(privateKey, ethers.provider);
    const tx = await wallet.sendTransaction({
        from: await getAddress(sender),
        to: await getAddress(receiver),
        value: parseUnits("0.0000001", "ether"),
        nonce: await wallet.getNonce(),
      });
}

function getContractAddressOnChain(contract, chain) {
    let address = JSON.parse(fs.readFileSync(
        './deployments/'+chain+'/'+contract+'.json','utf-8')).address;
    return address;
}

async function getContractArtifacts(name) {
    const contractAddress = await Promise.all([
        hre.deployments.get(name).then(d => d),
    ])
    return contractAddress[0];
}

async function getAddress(user) {
    if((user.startsWith('0x')) && (user.length == 42)) {
            return ethers.getAddress(user);
    }
    const unNamedAccounts = await hre.getUnnamedAccounts();
    if (user in constants.namedAccountToIndex) {
        return unNamedAccounts[constants.namedAccountToIndex[user]];
    } else {
        return (await getContractArtifacts(user)).address;
    }
}

async function getAddressOnChain(user,chain) {
    if((user.startsWith('0x')) && (user.length == 42)) {
            return ethers.utils.getAddress(user);
    }
    const unNamedAccounts = await hre.getUnnamedAccounts();
    if (user in constants.namedAccountToIndex) {
        return unNamedAccounts[constants.namedAccountToIndex[user]];
    } else {
        return getContractAddressOnChain(user,chain);
    }
}

async function getContract(name) {
    let cArtifacts = await getContractArtifacts(name)
    let contract = new ethers.Contract(cArtifacts.address, cArtifacts.abi, ethers.provider);
    return contract;
}

async function getContractWithSigner(name,signer) {
    let contract = await getContract(name);
    let privateKey = getPrvKey(signer);
    let wallet = new ethers.Wallet(privateKey, ethers.provider);
    let contractWithSigner = contract.connect(wallet);
    return contractWithSigner;
}

function nameToChainId(chain) {
    return parseInt(fs.readFileSync('./deployments/'+chain+'/.chainId','utf-8'));
}

function chainIdToName(chainId) {
    let getDirectories = function(path) {
        return fs.readdirSync(path).filter(function (file) {
          return fs.statSync(path+'/'+file).isDirectory();
        });
    }
    let dirs = getDirectories('./deployments/');
    for(let i =0; i< dirs.length; i++) {
        let cChainId = parseInt(fs.readFileSync('./deployments/'+dirs[i]+'/.chainId','utf-8'));
        if(parseInt(chainId) == cChainId) {
            return dirs[i];
        }
    }
}

function _logData(newData,file) {
    let data;
    if(fs.existsSync(file)) {
        data = JSON.parse(fs.readFileSync(file, 'utf8'));
        data.logs.push(newData)
    } else {
        data = {
            logs : [newData]
        }
    }
    fs.writeFileSync(file, JSON.stringify(data,null,4), function() {}); 
}

function logResult(retval) {
    let logFile = constants.logFile;
    _logData(retval,logFile);
}

function logAck(retval) {
    let logFile = constants.logAckFile;
    _logData(retval,logFile);
}

module.exports = {
    isCoreChain:isCoreChain,
    isDplatChain:isDplatChain,
    getL1Balance:getL1Balance,
    getAddress:getAddress,
    getPrvKey:getPrvKey,
    getAddressOnChain:getAddressOnChain,
    getContractArtifacts:getContractArtifacts,
    getContract:getContract,
    getContractWithSigner:getContractWithSigner,
    nameToChainId:nameToChainId,
    chainIdToName:chainIdToName,
    logResult:logResult,
    logAck:logAck,
    transferL1:transferL1
}
