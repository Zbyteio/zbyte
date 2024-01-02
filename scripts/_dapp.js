const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("./lib.js");
const chai = require("chai");
const expect = chai.expect;
const fwd = require("./_fwdExecCore.js");


async function _getEncodedData(cname,
    functionName, params) {
let cArtifacts = await lib.getContractArtifacts(cname);
let ABI = cArtifacts.abi;
let iface = new ethers.Interface(ABI);
let encodedData = iface.encodeFunctionData(functionName, params);
return encodedData;
}

async function _makeCall(invoker, req) {
    let privateKey = lib.getPrvKey(invoker);
    let wallet = new ethers.Wallet(privateKey, ethers.provider);
    req = await wallet.populateTransaction(req);
    const tx = await wallet.sendTransaction(req);
    let receipt = await tx.wait();
    return receipt;
}

async function _makeCallView(req) {
    let wallet = ethers.provider;
    const ret = await wallet.call(req);
    return ret;
}

async function invoke(dapp,invoker,functionName,functionParams) {
    try {
        console.log("invoke",dapp,invoker,functionName,functionParams)
        let dappAddress = await lib.getAddress(dapp);
        let invokerAddress = await lib.getAddress(invoker);
        let paramsArray = [];
        if (functionParams != undefined) {
            paramsArray = functionParams.split(',');
        }
        const encodedData = await _getEncodedData(dapp,functionName,paramsArray);
        console.log("encodedData: ", encodedData);
        const req = {
            from: invokerAddress,  // original signer, msg.sender
            to: dappAddress, // target contract
            value: '0',
            gas: '10000000',
            //nonce: nonce.toString(),
            data: encodedData  // <change> what is the call
          };
        let receipt = await _makeCall(invoker, req);
        return {function: "invoke",
                dapp: dappAddress,
                invoker: invokerAddress,
                fnName: functionName,
                fnParams: functionParams}
    } catch (error) {
        console.log(error);
    }

}

async function invokeView(dapp,functionName,functionParams) {
    try {
        console.log("invoke view:",dapp,functionName,functionParams)
        let dappAddress = await lib.getAddress(dapp);
        let paramsArray = [];
        if (functionParams != undefined) {
            paramsArray = functionParams.split(',');
        }
        const encodedData = await _getEncodedData(dapp,functionName,paramsArray);
        console.log("encodedData: ", encodedData);
        const req = {
            to: dappAddress, // target contract
            data: encodedData  // <change> what is the call
          };
        let ret = await _makeCallView(req);
        console.log(ret);
        return {function: "invokeView",
                dapp: dappAddress,
                fnName: functionName,
                fnParams: functionParams,
                result: ret}
    } catch (error) {
        console.log(error);
    }

}

async function invokeViaForwarder(dapp,invoker,functionName,functionParams) {
    try {
        let paramsArray = [];
        if (functionParams != undefined) {
            paramsArray = functionParams.split(',');
        }
        let dappAddress = await lib.getAddress(dapp);
        let invokerAddress = await lib.getAddress(invoker);

        console.log("invoke via fwd:",dapp,invoker,functionName,paramsArray)
        let ret = await fwd.executeViaForwarder("ZbyteForwarderDPlat",dapp,invoker,functionName,paramsArray)
        let receipt = await fwd.fwdExec("ZbyteForwarderDPlat",ret.req,ret.sign,"wrkr");

        return {function: "invokeViaForwarder",
                dapp: dappAddress,
                invoker: invokerAddress,
                fnName: functionName,
                fnParams: functionParams}
    } catch (error) {
        console.log(error);
    }

}

module.exports = {
    invoke:invoke,
    invokeView:invokeView,
    invokeViaForwarder:invokeViaForwarder
}