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

async function nativeEthEquivalentZbyteInGwei() {
    try {
        let contract = await lib.getContract(contractName);

        const ret = await contract.nativeEthEquivalentZbyteInGwei();

        return { function: "nativeEthEquivalentZbyteInGwei",
                 "value": ret
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

async function registerWorker(owner,worker) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);

        const tx = await contractWithSigner.registerWorker(await lib.getAddress(worker), true);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"WorkerRegistered")
        .withArgs(await lib.getAddress(worker), true);

        return { function: "registerWorker",
                 "worker": await lib.getAddress(worker)
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

module.exports = {
"setZbytePriceInGwei":setZbytePriceInGwei,
"setNativeEthEquivalentZbyteInGwei":setNativeEthEquivalentZbyteInGwei,
"setBurnRateInMill":setBurnRateInMill,
"registerWorker":registerWorker,
nativeEthEquivalentZbyteInGwei:nativeEthEquivalentZbyteInGwei
}
