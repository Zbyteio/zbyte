const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("./lib.js");
const chai = require("chai");
const expect = chai.expect;

const contractName = "ZbyteAirdropNFT";

async function mintForAirdrop(amount,uri,startTokenId,owner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        console.log("mintForAirdrop: " + amount,owner);
        const tx = await contractWithSigner.mintForAirdrop(amount,uri);
        await expect(tx.wait())
                .to.emit(contractWithSigner,"mintedForAirdrop")
                .withArgs(amount,startTokenId);
        
        return {function: "mintForAirdrop",
                amount: amount,
                startTokenId:startTokenId}
    } catch (error) {
        console.log(error);
    }
}

async function safeTransferFrom(tokenId,to,distributor) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, distributor);
        let toAddress = await lib.getAddress(to);
        let fromAddress = await lib.getAddress(distributor);
        let owner = await contractWithSigner.ownerOf(tokenId);
        console.log("owner",tokenId,owner);
        console.log("transfer: " + tokenId,toAddress,fromAddress);
        const tx = await contractWithSigner.safeTransferFrom(fromAddress,toAddress,tokenId);
        await expect(tx.wait())
                .to.emit(contractWithSigner,"Transfer")
                .withArgs(fromAddress,toAddress,tokenId);
        return {function: "safeTransferFrom",
                fromAddress: fromAddress,
                toAddress:toAddress,
                tokenId:tokenId}
    } catch (error) {
        console.log(error);
    }
}

async function ownerOf(tokenId) {
    try {
        let contract = await lib.getContract(contractName);
        let owner = await contract.ownerOf(tokenId);
        return {function: "ownerOf",
            owner: owner}
    } catch (error) {
        console.log(error);
    }
}

async function redeem(receiver,user) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, user);
        let userAddress = await lib.getAddress(user);
        let receiverAddress = await lib.getAddress(receiver);
        let numTokens = await contractWithSigner.balanceOf(userAddress);
        console.log("redeem",user,userAddress,numTokens);
        const tx = await contractWithSigner.redeem(receiverAddress);
        await expect(tx.wait())
                .to.emit(contractWithSigner,"Redeemed")
                .withArgs(userAddress,numTokens);
        return {function: "Redeemed",
                userAddress: userAddress,
                numTokens:numTokens}
    } catch (error) {
        console.log(error);
    }
}

async function transferRemainingERC20(recepient,owner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        let recepientAddress = await lib.getAddress(recepient);
        console.log("transferRemainingERC20: " + owner,recepientAddress);
        const tx = await contractWithSigner.transferRemainingERC20(recepientAddress);
        await expect(tx.wait())
        
        return {function: "transferRemainingERC20"}
    } catch (error) {
        console.log(error);
    }
}

module.exports = {
    mintForAirdrop:mintForAirdrop,
    safeTransferFrom:safeTransferFrom,
    ownerOf:ownerOf,
    redeem:redeem,
    transferRemainingERC20:transferRemainingERC20
}