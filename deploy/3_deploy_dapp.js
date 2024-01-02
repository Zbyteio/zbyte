const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("../scripts/lib.js");
const fs = require("fs");

// TODO add fwd changes, vZbyte, dplat
async function deployDapp(dapp,depl) {
    let ret = {};

    if(!(lib.isDplatChain())) {
        console.log("Fail: current chain:",hre.network.name);
        return ret;
    }
    if(dapp == "SampleDstoreDapp") {
        let deployer = await lib.getAddress(depl)

        let fwdDplatAddress = await lib.getAddress('ZbyteForwarderDPlat');
        SampleDstoreDapp = await hre.deployments.deploy(
            'SampleDstoreDapp', {
                from:deployer,
                args: [fwdDplatAddress],
                gasLimit: 6e6,
                deterministicDeployment: false
            })
        console.log('==SampleDstoreDapp addr=', SampleDstoreDapp.address);
        ret = {
            function:"deployDapp",
            dapp: dapp,
            dappAddress: SampleDstoreDapp.address,
            deployer: deployer
        }
    }
    return ret;
}

module.exports = deployDapp
