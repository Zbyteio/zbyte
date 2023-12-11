const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("./lib.js");
const chai = require("chai");
const expect = chai.expect;

const contractName = "ZbyteRelay";

async function addRelayApprovee(owner,approvee) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        let approveeAddress = await lib.getAddress(approvee);
  
        console.log("addRelayApprovee: " + approveeAddress);

        const tx = await contractWithSigner.addRelayApprovee(approveeAddress);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"RelayApproveeAdded")
        .withArgs(approveeAddress);

        return { function: "addRelayApprovee",
                 approveeAddress: approveeAddress
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function setRelayWrapper(owner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
        let relayWrapperAddress = await lib.getAddress("RelayWrapper");
  
        console.log("setRelayWrapper: " + relayWrapperAddress);
  
        const tx = await contractWithSigner.setRelayWrapper(relayWrapperAddress);
        await expect(tx.wait())
        .to.emit(contractWithSigner,"RelayWrapperSet")
        .withArgs(relayWrapperAddress);

        return { function: "setRelayWrapper",
                 relayWrapperAddress: relayWrapperAddress
               }
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function receiveCall(srcChain, srcRelay, destChain, destRelay, payload, amount,owner) {
    try {
        let srcChainId = lib.nameToChainId(srcChain)
        const abiCoder = new ethers.AbiCoder();
        let uPlFields = abiCoder.decode(["address","bytes"],payload);
        let plFields = abiCoder.decode(["uint256","address","bytes32","address","bytes"],uPlFields[1]);
        let contractWithSigner = await lib.getContractWithSigner(contractName,owner);

        /* example for mumbai -> fuji deposit/mint */
        let destChainId = Number(plFields[0]);  // fuji
        let destContract = plFields[1];  // vZBYT on fuji
        let ack = plFields[2];           // generated by escrow on deposit
        let callbackContract = plFields[3];  // escrow
        let destCalldata = plFields[4];      // encode(mint(),beneficiary,amount)
        let callPayload = uPlFields[1];
        console.log("receiveCall: " + srcChainId + "," + srcRelay + "," + destChainId + "," + destRelay + "," + payload);
        console.log("receiveCall:" + ack + "," + callbackContract)

        let ackPayload;
        if (ack == '0x'+'0'.repeat(64)) {
            console.log("ack=0");
            // no acknowledement needed.  So, there won't be another callRemote made
            const tx = await contractWithSigner.receiveCall(srcChainId,srcRelay,payload);
            await expect(tx.wait())
                .to.emit(contractWithSigner,"RelayReceiveCallExecuted") //dest side relay called, target fn executed
                .withArgs(callPayload,true,0)
            ackPayload = "";
        } else {
            console.log("ack!=0");
            let amountWei = ethers.parseUnits(amount,18)
            // needs ack.  So, another callRemote made, resulting in RelayCallRemoteReceived event
            let ABI = [ "function callbackHandler(uint256,bytes32,bool,uint256)" ];
            let iface = new ethers.Interface(ABI);
            var ackCallData =  iface.encodeFunctionData("callbackHandler", [destChainId,ack,true,amountWei]);
            ackPayload = await contractWithSigner.updatePayload(srcChainId,callbackContract,'0x'+'0'.repeat(64),
                ethers.ZeroAddress,ackCallData)
            const tx = await contractWithSigner.receiveCall(srcChainId,srcRelay,payload);
            await expect(tx.wait())
                .to.emit(contractWithSigner,"RelayReceiveCallExecuted") //dest side relay called, target fn executed
                .withArgs(callPayload,true,amountWei)
                .to.emit(contractWithSigner,"RelayCallRemoteReceived") //dest side relay now becomes src side and initiates ack
                .withArgs(destChainId,destRelay,srcChainId,srcRelay,ackPayload);
        }
        let retval = {  function: 'receiveCall',
                        srcChain: hre.network.name, srcRelay: destRelay,
                        destChain: srcChain, destRelay: srcRelay, data: ackPayload,
                        ack:ack, caller:'relay'};
        console.log(retval);
        return retval;
    } catch (error) {
        console.log(error);
    }
}

module.exports = {
    addRelayApprovee:addRelayApprovee,
    setRelayWrapper:setRelayWrapper,
    receiveCall:receiveCall
}
