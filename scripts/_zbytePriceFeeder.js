const hre = require("hardhat");
const ethers = hre.ethers;
const {keccak256} = require("@ethersproject/keccak256")
const {toUtf8Bytes} = require("@ethersproject/strings")
const lib = require("./lib.js");
const chai = require("chai");
const expect = chai.expect;
const constants = require("./constants.js");

const contractName = "ZbytePriceFeeder";

async function setNativeEthEquivalentZbyteInGwei(owner, nativeEthEquivalentZbyteInGwei_) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);

        const tx = await contractWithSigner.setNativeEthEquivalentZbyteInGwei(nativeEthEquivalentZbyteInGwei_);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"NativeEthEquivalentZbyteSet")
        .withArgs(nativeEthEquivalentZbyteInGwei_);

        return { function: "setNativeEthEquivalentZbyteInGwei",
                 "nativeEthEquivalentZbyteInGwei": nativeEthEquivalentZbyteInGwei_
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function setZbytePriceInGwei(owner, zbytePriceInGwei_) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);

        const tx = await contractWithSigner.setZbytePriceInGwei(zbytePriceInGwei_);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"ZbytePriceInGweiSet")
        .withArgs(zbytePriceInGwei_);

        return { function: "setNativeEthEquivalentZbyteInGwei",
                 "zbytePriceInGwei_": zbytePriceInGwei_
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function setBurnRateInMill(owner, burnRateInMill_) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);

        const tx = await contractWithSigner.setBurnRateInMill(burnRateInMill_);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"BurnRateInMillSet")
        .withArgs(burnRateInMill_);

        return { function: "setBurnRateInMill",
                 "burnRateInMill": burnRateInMill_
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function setApproveAndDepositGasCost(owner, relayName, chain, gasCostInZbyte_) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);

        let relayId = constants.relayNameToId[relayName];
        let chainId = lib.nameToChainId(chain);
        console.log("setApproveAndDepositGasCost: ", relayId, chainId, gasCostInZbyte_);
        const tx = await contractWithSigner.setApproveAndDepositGasCost(relayId, chainId, gasCostInZbyte_);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"ApproveAndDepositGasCostSet")
        .withArgs(relayId, chainId, gasCostInZbyte_);

        return { function: "setApproveAndDepositGasCost",
                 "relayId_": relayId,
                 "remoteChainId_": chainId,
                 "gasCost_": gasCostInZbyte_
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

module.exports = {
"setApproveAndDepositGasCost":setApproveAndDepositGasCost,
"setZbytePriceInGwei":setZbytePriceInGwei,
"setNativeEthEquivalentZbyteInGwei":setNativeEthEquivalentZbyteInGwei,
"setBurnRateInMill":setBurnRateInMill
}