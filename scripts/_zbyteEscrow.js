const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("./lib.js");
const chai = require("chai");
const expect = chai.expect;
const constants = require("./constants.js");

const contractName = "ZbyteEscrow";

async function deposit(relay,dplatChain,receiver,amount,sender) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, sender);
        var amountWei = ethers.parseUnits(amount,18);
        let dplatChainId = lib.nameToChainId(dplatChain);
        let coreChainId = lib.nameToChainId(hre.network.name)
        let receiverAddress = await lib.getAddressOnChain(receiver,dplatChain);
        let senderAddress = await lib.getAddress(sender);

        let nonce = await contractWithSigner.getNonce();
        let ack = ethers.solidityPackedKeccak256(["uint256","address","uint256","uint256"],
                [dplatChainId,receiverAddress,amountWei,nonce]);
        let relayContract = await lib.getContract("ZbyteRelay")

        console.log("deposit: " + dplatChainId + "," + receiverAddress + "," +
            amountWei + "," + senderAddress);
        let destRelay = await lib.getAddressOnChain('ZbyteRelay',dplatChain);
        let zbyteVTokenAddress = await lib.getAddressOnChain('ZbyteVToken',dplatChain);
        let vAddressStored = await contractWithSigner.vERC20Addresses(dplatChainId);

        expect(zbyteVTokenAddress).to.equal(vAddressStored);
        let relayWrapper = await lib.getContract('RelayWrapper');

        let cArtifacts = await lib.getContractArtifacts("ZbyteVToken");
        let ABI = cArtifacts.abi;
        let iface = new ethers.Interface(ABI);
        var mintCallData =  iface.encodeFunctionData("mint", [receiverAddress,amountWei]);

        let payload = await relayWrapper.updatePayload(dplatChainId,zbyteVTokenAddress,ack,
                            await lib.getAddress("ZbyteEscrow"),mintCallData)
        let relayId = constants.relayNameToId[relay];

        const tx = await contractWithSigner.deposit(relayId,dplatChainId,receiverAddress,amountWei);
        await expect(tx.wait())
                      .to.emit(contractWithSigner,"ERC20Deposited")  // Escro called relay
                      .withArgs(senderAddress,receiverAddress,amountWei,dplatChainId,ack)
                      .to.emit(relayContract,"RelayCallRemoteReceived")  // source side relay received call
                      .withArgs(coreChainId,relayContract.target,dplatChainId,destRelay,payload);
           
        let retval = { function: "deposit",
                       srcChain: hre.network.name, srcRelay: relayContract.target,
                       destChain: dplatChain, destRelay: destRelay, data: payload,
                       ack:ack, amount: amount, caller:'escrow'};
        return retval;
    } catch (error) {
        console.log(error);
    }
}

async function withdraw(relay,dplatChain,paymaster,receiver,owner) {
    try{
  
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        let dplatChainId = lib.nameToChainId(dplatChain);
        let receiverAddress = await lib.getAddress(receiver);
        let paymasterAddress = await lib.getAddressOnChain(paymaster,dplatChain);
        let nonce = await contractWithSigner.getNonce();
  
        let ack = ethers.solidityPackedKeccak256(["uint256","address","address","uint256"],
                [dplatChainId,paymasterAddress,receiverAddress,nonce]);
  
        let relayContract = await lib.getContract("ZbyteRelay")
        console.log("withdraw: " + dplatChainId + "," + receiverAddress + "," + paymasterAddress);
        let coreChainId = lib.nameToChainId(hre.network.name)
        let destRelay = await lib.getAddressOnChain('ZbyteRelay',dplatChain);
        let zbyteVTokenAddress = await lib.getAddressOnChain('ZbyteVToken',dplatChain);
        let vAddressStored = await contractWithSigner.vERC20Addresses(dplatChainId);
  
        expect(zbyteVTokenAddress).to.equal(vAddressStored);
        let relayWrapper = await lib.getContract('RelayWrapper');
  
        let ABI = [ "function destroy(address account)" ];
        let iface = new ethers.Interface(ABI);
        var destroyCallData =  iface.encodeFunctionData("destroy", [paymasterAddress]);
        let payload = await relayWrapper.updatePayload(dplatChainId,vAddressStored,ack,
                            contractWithSigner.target,destroyCallData)
        let ownerAddress = await lib.getAddress(owner);
        let relayId = constants.relayNameToId[relay];
        const tx = await contractWithSigner.withdraw(relayId,dplatChainId,paymasterAddress,receiverAddress);
        await expect(tx.wait())
                      .to.emit(contractWithSigner,"ERC20Withdrawn")  // Escro called relay
                      .withArgs(ownerAddress,paymasterAddress,receiverAddress,dplatChainId,ack)
                      .to.emit(relayContract,"RelayCallRemoteReceived")  // source side relay received call
                      .withArgs(coreChainId,relayContract.target,dplatChainId,destRelay,payload);

        let retval = { function: "withdraw",
                       srcChain: hre.network.name, srcRelay: relayContract.target,
                       destChain: dplatChain, destRelay: destRelay.target, data: payload,
                       ack:ack,caller:'escrow'};
        return retval;
    } catch (error) {
        console.log(error);
    }
  }
  

async function setvERC20Address(owner,dplatChain) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        let zbyteVTokenAddress = await lib.getAddressOnChain("ZbyteVToken",dplatChain);

        let dplatChainId = lib.nameToChainId(dplatChain);
        console.log("setvERC20Address: " + zbyteVTokenAddress +"," + dplatChainId + "," + dplatChain);

        const tx = await contractWithSigner.setvERC20Address(zbyteVTokenAddress,dplatChainId);
        await expect(tx.wait())
            .to.emit(contractWithSigner,"vERC20AddressSet")
            .withArgs(zbyteVTokenAddress,dplatChainId);

        return { function : "setvERC20Address",
                 vERC20Address: zbyteVTokenAddress,
                 dplatChainId: dplatChainId
                }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function setRelayWrapperAddress(owner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        let relayWrapperAddress = await lib.getAddress("RelayWrapper");
  
        console.log("setRelayWrapperAddress: " + relayWrapperAddress);

        const tx = await contractWithSigner.setRelayWrapperAddress(relayWrapperAddress);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"RelayWrapperAddressSet")
        .withArgs(relayWrapperAddress);

        return { function: "setRelayWrapperAddress",
                 relayWrapperAddress: relayWrapperAddress
               }
    } catch (error) {
        console.log(error);
        throw(error);
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

async function getPendingAction(ack) {
    try {
        let contract = await lib.getContract(contractName);
        let ret = await contract.pendingAction(ack);
        console.log("getPendingAction:"+ack+","+ret);
        return {function: "getPendingAction",
                pendingAction: ret}
    } catch (error) {
        console.log(error);
    }  
}


module.exports = {
    setvERC20Address:setvERC20Address,
    setRelayWrapperAddress:setRelayWrapperAddress,
    deposit:deposit,
    withdraw:withdraw,
    pause:pause,
    unpause:unpause,
    getPendingAction:getPendingAction
}
