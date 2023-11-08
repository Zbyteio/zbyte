const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("./lib.js");
const chai = require("chai");
const expect = chai.expect;
const constants = require("./constants.js");

const contractName = "RelayWrapper";

async function setEscrowAddress(owner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        let ZbyteEscrowAddress = await lib.getAddress("ZbyteEscrow");
  
        console.log("setEscrowAddress: " + ZbyteEscrowAddress);

        const tx = await contractWithSigner.setEscrowAddress(ZbyteEscrowAddress);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"EscrowAddressSet")
        .withArgs(ZbyteEscrowAddress);

        return { function: "setEscrowAddress",
                 ZbyteEscrowAddress: ZbyteEscrowAddress
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function setRelayAddress(owner,chain,relayName) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        let relayId = constants.relayNameToId[relayName];
        let relayAddress = await lib.getAddressOnChain(relayName,chain);
        let chainId = lib.nameToChainId(chain);
  
        console.log("setRelayAddress: " + owner + "," + chainId + "," +relayId + "," + relayAddress);

        const tx = await contractWithSigner.setRelayAddress(chainId,relayId,relayAddress);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"RelayAddressSet")
        .withArgs(chainId,relayId,relayAddress);

        return { function: "setRelayAddress",
                 relayAddress: relayAddress,
                 relayId:relayId,
                 chainId:chainId
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

module.exports = {
    setEscrowAddress:setEscrowAddress,
    setRelayAddress:setRelayAddress
}