const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("./lib.js");
const chai = require("chai");
const constants = require("./constants.js");
const fwdExecCore = require("./_fwdExecCore.js");
const expect = chai.expect;

const contractName = "ZbyteVToken";

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

async function pause(owner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        let ownerAddress = await lib.getAddress(owner);

        console.log("pause");
        const tx = await contractWithSigner.pause();
        await expect(tx.wait())
                .to.emit(contractWithSigner,"Paused")
                .withArgs(ownerAddress);
        return {function: "pause"}
    } catch (error) {
        console.log(error);
    }
}

async function unpause(owner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        let ownerAddress = await lib.getAddress(owner);

        console.log("pause");
        const tx = await contractWithSigner.unpause();
        await expect(tx.wait())
                .to.emit(contractWithSigner,"Unpaused")
                .withArgs(ownerAddress);
        return {function: "unpause"}
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

async function royaltyTransferFrom(approvee, sender, receiver, amount) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, approvee);

        var amountWei = ethers.parseUnits(amount,18);
        var approveeAddress = await lib.getAddress(approvee);
        var senderAddress = await lib.getAddress(sender);
        var receiverAddress = await lib.getAddress(receiver);
        console.log("royaltyTransferFrom: " + approveeAddress + "," + senderAddress + "," +
            amountWei + "," + receiverAddress);
        const tx = await contractWithSigner.royaltyTransferFrom(senderAddress,receiverAddress,amountWei);
        await expect(tx.wait())
                .to.emit(contractWithSigner,"Transfer")
                .withArgs(senderAddress,receiverAddress,amountWei);
        return {function: "royaltyTransferFrom",
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

async function setPaymasterAddress(owner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        
        let paymasterAddress = await lib.getAddress("ZbyteForwarderDPlat");
        console.log("setPaymasterAddress: " + paymasterAddress);
        const tx = await contractWithSigner.setPaymasterAddress(paymasterAddress);
        await expect(tx.wait())
            .to.emit(contractWithSigner,"PaymasterAddressSet")
            .withArgs(paymasterAddress);

        return {function: "setPaymasterAddress",
            paymasterAddress: paymasterAddress}
        } catch (error) {
        throw(error);
    }
}

async function mint(owner,user,amount) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        
        var amountWei = ethers.parseUnits(amount,18);
        var userAddress = await lib.getAddress(user);
        console.log("mint: " + userAddress + "," + amountWei);
        const tx = await contractWithSigner.mint(userAddress,amountWei);
        await expect(tx.wait())
            .to.emit(contractWithSigner,"Transfer")
            .withArgs(ethers.ZeroAddress,userAddress,amountWei);
        return {function: "mint",
            user: userAddress,
            amount: ethers.formatUnits(amountWei,18)}
        } catch (error) {
        throw(error);
    }
}

async function setRoleCapability(role, fnSig, enabled, owner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        
        let cArtifacts = await lib.getContractArtifacts("ZbyteVToken");
        let ABI = cArtifacts.abi;
        let iface = new ethers.Interface(ABI);
        let fnSelector = iface.getFunction(fnSig).selector;
        console.log("setRoleCapability: " + role + "," + fnSelector + "," + enabled);
        const tx = await contractWithSigner.setRoleCapability(role,fnSelector,enabled);
        await expect(tx.wait())
            .to.emit(contractWithSigner,"RoleCapabilityUpdated")
            .withArgs(role,fnSelector,enabled);
        return {function: "setRoleCapability",
            role: role,
            fnSig: fnSelector,
            enabled: enabled}
        } catch (error) {
        throw(error);
    }
}

async function setUserRole(user, role, enabled, owner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        
        let userAddress = await lib.getAddress(user);
        console.log("setUserRole: " + userAddress + "," + role + "," + enabled);
        const tx = await contractWithSigner.setUserRole(userAddress,role,enabled);
        await expect(tx.wait())
            .to.emit(contractWithSigner,"UserRoleUpdated")
            .withArgs(userAddress,role,enabled);
        return {function: "setUserRole",
            userAddress: userAddress,
            role: role,
            enabled: enabled}
        } catch (error) {
        throw(error);
    }
}

async function setZbyteDPlatAddress(owner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        
        let dplatAddress = await lib.getAddress("ZbyteDPlat");
        console.log("setZbyteDPlatAddress: " + dplatAddress);
        const tx = await contractWithSigner.setZbyteDPlatAddress(dplatAddress);
        await expect(tx.wait())
            .to.emit(contractWithSigner,"ZbyteDPlatAddressSet")
            .withArgs(dplatAddress);

        return {function: "setZbyteDPlatAddress",
            dplatAddress: dplatAddress}
        } catch (error) {
        throw(error);
    }
}

async function mintVZbyteGasless(user, receiver, amount, relay, dPlatChain) {
    try {
        const zbyteTokenContract = await lib.getContractWithSigner('ZbyteToken', user);
        const vZbyteTokenContract = await lib.getContract('ZbyteVToken');
        const zbyteEscrowContract = await lib.getContract('ZbyteEscrow');
        const relayContract = await lib.getContract(relay);
        const userAddress = await lib.getAddress(user);
        const receiverAddress = await lib.getAddress(receiver);

        const zbyteForwarderCoreContractWithSigner = await lib.getContractWithSigner('ZbyteForwarderCore', 'wrkr');

        let amountWei = ethers.parseUnits(amount, 18);

        let retApprove = await fwdExecCore.executeViaForwarder('ZbyteTokenForwarder', 'ZbyteToken', user, 'approve', [await lib.getAddress('ZbyteEscrow'), amountWei]);
        let retExecuteApprove = await fwdExecCore.executeViaForwarder('ZbyteForwarderCore', 'ZbyteTokenForwarder', user, 'execute', [retApprove.req, retApprove.sign]);
        let retDeposit = await fwdExecCore.executeViaForwarder('ZbyteForwarderCore', 'ZbyteEscrow', user, 'deposit', [constants.relayNameToId[relay], lib.nameToChainId(dPlatChain), receiverAddress, amountWei]);

        const tx = await zbyteForwarderCoreContractWithSigner.approveAndDeposit(retExecuteApprove.req, retExecuteApprove.sign, retDeposit.req, retDeposit.sign, {gasLimit:10000000});
        await expect(tx.wait())
        .to.emit(zbyteTokenContract,"Approval")
        .withArgs(userAddress, await lib.getAddress('ZbyteEscrow'), amountWei);
        await expect(tx.wait())
        .to.emit(zbyteTokenContract,"Transfer")
        .withArgs(userAddress, await lib.getAddress('ZbyteEscrow'), amountWei);
        await expect(tx.wait())
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

module.exports = {
    getContractDetails:getContractDetails,
    balanceOf:balanceOf,
    mint:mint,
    pause:pause,
    unpause:unpause,
    setRoleCapability:setRoleCapability,
    setUserRole:setUserRole,
    approve:approve,
    setZbyteDPlatAddress:setZbyteDPlatAddress,
    mintVZbyteGasless:mintVZbyteGasless,
    setPaymasterAddress:setPaymasterAddress,
    royaltyTransferFrom:royaltyTransferFrom
}