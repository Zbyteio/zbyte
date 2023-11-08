const hre = require("hardhat");
const ethers = hre.ethers;
const {keccak256} = require("@ethersproject/keccak256")
const {toUtf8Bytes} = require("@ethersproject/strings")
const lib = require("./lib.js");
const chai = require("chai");
const expect = chai.expect;

const contractName = "ZbyteDPlat";

async function setZbyteForwarderDPlat(owner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        let zbyteForwarderDPlat = await await lib.getAddress("ZbyteForwarderDPlat");
  
        console.log("setZbyteForwarderDPlat: " + zbyteForwarderDPlat);

        const tx = await contractWithSigner.setForwarder(zbyteForwarderDPlat);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"ForwarderSet")
        .withArgs(zbyteForwarderDPlat);

        return { function: "ForwarderSet",
                 ZbyteForwarderDPlat: zbyteForwarderDPlat
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function setZbyteVToken(owner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        let ZbyteVTokenAddress = await await lib.getAddress("ZbyteVToken");
  
        console.log("setZbyteVToken: " + ZbyteVTokenAddress);

        const tx = await contractWithSigner.setZbyteVToken(ZbyteVTokenAddress);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"ZbyteVTokenAddressSet")
        .withArgs(ZbyteVTokenAddress);

        return { function: "setZbyteVToken",
                ZbyteVToken: ZbyteVTokenAddress
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function setZbyteValueInNativeEthGwei(owner, zbyteValueInNativeEthGwei) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
  
        console.log("setZbyteValueInNativeEthGwei: " + zbyteValueInNativeEthGwei);

        const tx = await contractWithSigner.setZbyteValueInNativeEthGwei(zbyteValueInNativeEthGwei);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"ZbyteValueInNativeEthGweiSet")
        .withArgs(zbyteValueInNativeEthGwei);

        return { function: "setZbyteValueInNativeEthGwei",
                ZbyteValueInNativeEthGwei : zbyteValueInNativeEthGwei
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function registerProvider(owner, provider) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        const providerAddress = await lib.getAddress(provider);
        console.log("registerProvider: " + providerAddress);

        const tx = await contractWithSigner.registerProvider(providerAddress);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"ZbyteDPlatProviderRegistred")
        .withArgs(providerAddress,true)
        .to.emit(contractWithSigner,"ZbyteDPlatProviderAgentRegistered")
        .withArgs(providerAddress,providerAddress)
    
        return { function: "registerProvider",
                 ProviderAddress : providerAddress,
                 Register: true
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function registerProviderAgent(provider, providerAgent) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, provider);
        var providerAgentAddress = await lib.getAddress(providerAgent);
        var providerAddress = await lib.getAddress(provider);

        console.log("registerProviderAgent: " + providerAgentAddress);
        const tx = await contractWithSigner.registerProviderAgent(providerAgentAddress);

        console.log("registerProviderAgent: ", tx.hash);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"ZbyteDPlatProviderAgentRegistered")
        .withArgs(providerAgentAddress,providerAddress);

        return { function: "registerProvider",
                 ProviderAgentAddress : providerAgentAddress,
               }
    } catch (error) {
        console.log(error);
    }
}

async function registerEnterprise(providerAgent, enterprise) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, providerAgent);
        var entHash = keccak256(toUtf8Bytes(enterprise)).slice(0, 10)
        const providerAgentAddress = await lib.getAddress(providerAgent);
        var providerAddress = await lib.getAddress('prov');
        console.log("registerEnterprise: ", entHash, providerAgentAddress);

        const tx = await contractWithSigner.registerEnterprise(entHash);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"ZbyteDPlatEnterpriseRegistered")
        .withArgs(entHash,providerAddress);
        return { "function": "registerEnterprise",
                 "enterprise": entHash
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function registerEnterpriseUser(providerAgent, enterpriseUser, enterprise) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, providerAgent);
        var entHash = keccak256(toUtf8Bytes(enterprise)).slice(0, 10)

        const enterpriseUserAddress = await lib.getAddress(enterpriseUser);
        console.log("registerEnterpriseUser: ", enterpriseUserAddress, entHash);

        const tx = await contractWithSigner.registerEnterpriseUser(enterpriseUserAddress, entHash);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"ZbyteDPlatEnterpriseUserRegistered")
        .withArgs(enterpriseUserAddress, entHash);
        return { "function": "registerEnterpriseUser",
                 "user": enterpriseUserAddress,
                 "enterprise": entHash
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function registerDapp(providerAgent, dapp, enterprise) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, providerAgent);
        var entHash = keccak256(toUtf8Bytes(enterprise)).slice(0, 10)

        const dappAddress = await lib.getAddress(dapp);
        console.log("registerDapp: ", dappAddress);

        const tx = await contractWithSigner.registerDapp(dappAddress,entHash);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"ZbyteDPlatDappRegistered")
        .withArgs(dappAddress, entHash);
        return { "function": "registerDapp",
                 "dapp": dappAddress,
                 "enterprise": entHash
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function setEnterpriseLimit(providerAgent, enterprise, limit) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, providerAgent);
        var entHash = keccak256(toUtf8Bytes(enterprise)).slice(0, 10)

        var limit_bn = limit +'0'.repeat(18)
        console.log("setEnterpriseLimit: ", entHash, limit_bn);

        const tx = await contractWithSigner.setEnterpriseLimit(entHash, limit_bn);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"ZbyteDPlatEnterpriseLimitSet")
        .withArgs(entHash,limit_bn);
        return { "function": "registerDapp",
                 "enterprise": entHash,
                 "limit": limit_bn
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}


  
async function setZbyteBurnFactor(owner, factor) {
    try {
      let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
  
      console.log("setZbyteBurnFactor: ", factor);

      const tx = await contractWithSigner.setZbyteBurnFactor(factor);
      await expect(tx.wait())
      .to.emit(contractWithSigner,"ZbyteBurnFactorSet")
      .withArgs(factor);
  
      return { function: "setZbyteBurnFactor",
               BurnFactor: factor
             }
  
    } catch (error) {
        console.log(error);
        throw(error);
    }
  }
  

module.exports = {
    "setZbyteVToken":setZbyteVToken,
    "setZbyteValueInNativeEthGwei":setZbyteValueInNativeEthGwei,
    "setZbyteForwarderDPlat":setZbyteForwarderDPlat,
    "registerProvider":registerProvider,
    "registerProviderAgent":registerProviderAgent,
    "registerEnterprise":registerEnterprise,
    "registerEnterpriseUser":registerEnterpriseUser,
    "registerDapp":registerDapp,
    "setEnterpriseLimit":setEnterpriseLimit,
    "setZbyteBurnFactor":setZbyteBurnFactor
}