const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("./lib.js");
const chai = require("chai");
const expect = chai.expect;
const ethSigUtil = require('eth-sig-util');

async function getFwdNonce(fwd,user) {
    let contract = await lib.getContract(fwd);
    let userAddress = await lib.getAddress(user);
    let nonce = await contract.getNonce(userAddress);
    return nonce;
}

async function getEncodedData(cname,
        functionName, params) {
    let cArtifacts = await lib.getContractArtifacts(cname);
    let ABI = cArtifacts.abi;
    let iface = new ethers.Interface(ABI);
    let encodedData = iface.encodeFunctionData(functionName, params);
    return encodedData;
}

async function fwdExec(fwd,req,sign,submitter) {
  const contractWithSigner = await lib.getContractWithSigner(fwd,submitter);
  var result = await contractWithSigner.verify(req,sign);
  console.log("verify:",result);
  if (result == true) {
    var call_result = await contractWithSigner.execute(req,sign);
    console.log("execute:",call_result);
  }
}

async function executeViaForwarder(fwd,targetContract,
                signer,functionName,functionParams) {
    const signerAddress = await lib.getAddress(signer);
    let signerPrivateKey = await lib.getPrvKey(signer);
    const targetContractAddress = await lib.getAddress(targetContract);
    const forwarderAddress = await lib.getAddress(fwd);
    let nonce = await getFwdNonce(fwd,signer);
    const signer_privateKeyBuffer = Buffer.from(signerPrivateKey, 'hex')

    const encodedData = await getEncodedData(targetContract,functionName,functionParams);
    console.log("encodedData: ", encodedData);
    const req = {
        from: signerAddress,  // original signer, msg.sender
        to: targetContractAddress, // target contract
        value: '0',
        gas: '10000000',
        nonce: nonce.toString(),
        data: encodedData  // <change> what is the call
      };

    const chainId = lib.nameToChainId(hre.network.name);
      const domain = {
        name:'MinimalForwarder',
        version:'0.0.1',
        chainId: chainId,
        verifyingContract: forwarderAddress,
      };
      const EIP712Domain = [
        { name: 'name', type: 'string' },
        { name: 'version', type: 'string' },
        { name: 'chainId', type: 'uint256' },
        { name: 'verifyingContract', type: 'address' },
      ];
      const types = {
        EIP712Domain,
        ForwardRequest: [
          { name: 'from', type: 'address' },
          { name: 'to', type: 'address' },
          { name: 'value', type: 'uint256' },
          { name: 'gas', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
          { name: 'data', type: 'bytes' },
        ],
      };

      signerPrivateKey = '0x' + signerPrivateKey;
      var sign = () => ethSigUtil.signTypedMessage(
        signer_privateKeyBuffer,  // original signer
        {
          data: {
            types: types,
            domain: domain,
            primaryType: 'ForwardRequest',
            message: req,
          },
        },
      );
      return {req:req, sign:sign()}
}
/*
(async () => {
        let ret = await executeViaForwarder("ZbyteToken",
            "zbyt","mint",[await lib.getAddress("comd"),ethers.parseUnits("100",18)])
        await fwdExec(ret.req,ret.sign,"comp");

        let amount = "100"
        ret = await executeViaForwarder("ZbyteToken",
            "zbyt","mint",[await lib.getAddress("comd"),ethers.parseUnits(amount,18)])
        let userAddress = await lib.getAddress("comd");
        let amountWei = ethers.parseUnits(amount,18)
        const tokenC = await lib.getContract("ZbyteToken")

        const contractWithSigner = await lib.getContractWithSigner(fwdCore,"comp");
        await expect(contractWithSigner.execute(ret.req,ret.sign))
        .to.emit(tokenC,"Transfer")
        .withArgs(ethers.ZeroAddress,userAddress,amountWei);
    })();
*/
module.exports = {
    executeViaForwarder:executeViaForwarder,
    fwdExec:fwdExec
}
