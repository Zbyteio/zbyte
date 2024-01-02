const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("./lib.js");
const chai = require("chai");
const expect = chai.expect;
const fwdExecCore = require("./_fwdExecCore.js");
const constants = require("./constants.js");

const contractName = "ZbyteForwarderCore";

async function setZbyteAddress(owner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        let ZbyteAddress = await lib.getAddress("ZbyteToken");
  
        console.log("setZbyteAddress: " + ZbyteAddress);
        const tx = await contractWithSigner.setZbyteAddress(ZbyteAddress);
        
        await expect(tx.wait())
        .to.emit(contractWithSigner,"ZbyteAddressSet")
        .withArgs(ZbyteAddress);

        return { function: "setZbyteAddress",
                 ZbyteAddress: ZbyteAddress
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function setZbyteTokenForwarderAddress(owner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        let ZbyteForwarderAddress = await lib.getAddress("ZbyteTokenForwarder");
  
        console.log("setZbyteTokenForwarderAddress: " + ZbyteForwarderAddress);
        const tx = await contractWithSigner.setZbyteTokenForwarderAddress(ZbyteForwarderAddress);
        
        await expect(tx.wait())
        .to.emit(contractWithSigner,"ZbyteTokenForwarderAddressSet")
        .withArgs(ZbyteForwarderAddress);

        return { function: "setZbyteTokenForwarderAddress",
                 ZbyteForwarderAddress: ZbyteForwarderAddress
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }  
}

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

async function approveAndDeposit(relay,user,receiver,amount,dPlatChain,worker) {
    try {
        const zbyteTokenContract = await lib.getContractWithSigner('ZbyteToken', user);
        const vZbyteTokenContract = await lib.getContract('ZbyteVToken');
        const zbyteEscrowContract = await lib.getContract('ZbyteEscrow');
        const relayContract = await lib.getContract(relay);
        const userAddress = await lib.getAddress(user);
        const receiverAddress = await lib.getAddress(receiver);

        console.log("approveAndDeposit:"+relay+","+userAddress+","+receiverAddress+","+amount);

        const zbyteForwarderCoreContractWithSigner = await lib.getContractWithSigner('ZbyteForwarderCore', worker);

        let amountWei = ethers.parseUnits(amount, 18);

        let retApprove = await fwdExecCore.executeViaForwarder('ZbyteTokenForwarder', 'ZbyteToken', user, 'approve', [await lib.getAddress('ZbyteEscrow'), amountWei]);
        //let retExecuteApprove = await fwdExecCore.executeViaForwarder('ZbyteForwarderCore', 'ZbyteTokenForwarder', user, 'execute', [retApprove.req, retApprove.sign]);
        let retDeposit = await fwdExecCore.executeViaForwarder('ZbyteForwarderCore', 'ZbyteEscrow', user, 'deposit', [constants.relayNameToId[relay], lib.nameToChainId(dPlatChain), receiverAddress, 0,amountWei]);

        const tx = await zbyteForwarderCoreContractWithSigner.approveAndDeposit(retApprove.req, retApprove.sign, retDeposit.req, retDeposit.sign, {gasLimit:10000000});
        await expect(tx.wait())
        .to.emit(zbyteTokenContract,"Approval")
        .withArgs(userAddress, await lib.getAddress('ZbyteEscrow'), amountWei);
        await expect(tx.wait())
        .to.emit(zbyteTokenContract,"Transfer")
        .withArgs(userAddress, await lib.getAddress('ZbyteEscrow'), amountWei);
        await expect(tx.wait())
        return { function: "approveAndDeposit"
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

module.exports = {
    setZbyteAddress:setZbyteAddress,
    setEscrowAddress:setEscrowAddress,
    approveAndDeposit:approveAndDeposit,
    setZbyteTokenForwarderAddress:setZbyteTokenForwarderAddress
}
