const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("./lib.js");
const chai = require("chai");
const expect = chai.expect;

const contractName = "ZbyteToken";

async function getContractDetails() {
    let contract = await lib.getContract(contractName);

    let cname = await contract.name();
    let csymbol = await contract.symbol();
    return {function:"getContractDetails", 
            name: cname, symbol: csymbol};
}

async function balanceOf(user) {
    let contract = await lib.getContract(contractName);
    let userAddress = await lib.getAddress(user);
    let balanceZbyte = await contract.balanceOf(userAddress);
    let balanceL1 = await lib.getL1Balance(user);
    console.log("balanceOf: " + userAddress + "," +
        ethers.formatUnits(balanceZbyte) + "(Z)," + ethers.formatUnits(balanceL1)+"(L1)");
    return {function: "balanceOf",
            user:userAddress, 
            balZ: ethers.formatUnits(balanceZbyte,18),
            balL1: ethers.formatUnits(balanceL1,18)};
}

async function transfer(sender, receiver, amount) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, sender);

        var amountWei = ethers.parseUnits(amount,18);
        var senderAddress = await lib.getAddress(sender);
        var receiverAddress = await lib.getAddress(receiver);
        console.log("transfer: " + senderAddress + "," +
            amountWei + "," + receiverAddress);
        const tx = await contractWithSigner.transfer(receiverAddress,amountWei);
        await expect(tx.wait())
                .to.emit(contractWithSigner,"Transfer")
                .withArgs(senderAddress,receiverAddress,amountWei);
        return {function: "transfer",
                sender: senderAddress,
                receiver: receiverAddress,
                amount: ethers.formatUnits(amountWei,18)}
    } catch (error) {
        console.log(error);
    }
}

async function transferFrom(approvee, sender, receiver, amount) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, approvee);

        var amountWei = ethers.parseUnits(amount,18); 
        var approveeAddress = await lib.getAddress(approvee);
        var senderAddress = await lib.getAddress(sender);
        var receiverAddress = await lib.getAddress(receiver);
        console.log("transferFrom: " + approveeAddress + "," + senderAddress + "," +
            amountWei + "," + receiverAddress);
        const tx = await contractWithSigner.transferFrom(senderAddress,receiverAddress,amountWei);
        await expect(tx.wait())
                .to.emit(contractWithSigner,"Transfer")
                .withArgs(senderAddress,receiverAddress,amountWei);
        return {function: "transfer",
                sender: senderAddress, receiver: receiverAddress,
                amount: ethers.formatUnits(amountWei,18)}
    } catch (error) {
        console.log(error);
    }
}

async function approve(approver, approvee, amount) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, approver);

        var amountWei = ethers.parseUnits(amount,18);
        var approveeAddress = await lib.getAddress(approvee);
        var approverAddress = await lib.getAddress(approver);
        console.log("approve: " + approveeAddress + "," + amountWei +
            "," + approverAddress);
        const tx = await contractWithSigner.approve(lib.getAddress(approvee),amountWei);
        await expect(tx.wait())
            .to.emit(contractWithSigner,"Approval")
            .withArgs(approverAddress,approveeAddress,amountWei);   
        return {function: "approve",
                approver: approverAddress, approvee: approveeAddress, 
                amount: ethers.formatUnits(amountWei,18)}
    } catch (error) {
        console.log(error);
    }
}

module.exports = {
    getContractDetails:getContractDetails,
    balanceOf:balanceOf,
    transfer:transfer,
    transferFrom:transferFrom,
    approve:approve
}