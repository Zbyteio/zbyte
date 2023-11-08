const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("./lib.js");
const chai = require("chai");
const expect = chai.expect;
const fwdExecCore = require("./_fwdExecCore.js");

const contractName = "SampleDstoreDapp";

async function storeValue(user, value) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, user);
        const userAddress = await lib.getAddress(user);
        console.log("storeValue: ", userAddress, value);
        const tx = await contractWithSigner.storeValue(value);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"DStoreSet")
        .withArgs(userAddress,value);
        return { "function": "storeValue",
                 "storedBy": userAddress,
                 "storedValue": value
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function storeValueViaFwd(submitter, user, value) {
    try {
        const fwd = "ZbyteForwarderDPlat";
        const storeValueContractWithSigner = await lib.getContractWithSigner(contractName, submitter);
        let contractWithSigner = await lib.getContractWithSigner(fwd, submitter);
        let userAddress = await lib.getAddress(user);
        let ret = await fwdExecCore.executeViaForwarder(fwd, contractName, user, "storeValue", [value]);
        console.log("executeViaForwarder ret: ", ret);

        const tx = await contractWithSigner.zbyteExecute(ret.req, ret.sign, {gasLimit:2000000});
        await expect(tx.wait())
        .to.emit(storeValueContractWithSigner,"DStoreSet")
        .withArgs(userAddress,value);
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

module.exports = {
    "storeValue":storeValue,
    "storeValueViaFwd":storeValueViaFwd
}