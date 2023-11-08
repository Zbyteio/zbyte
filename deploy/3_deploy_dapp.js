const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("../scripts/lib.js");
const fs = require("fs");

// TODO add fwd changes, vZbyte, dplat
async function deployDapp() {

    if(!(lib.isDplatChain())) {
        console.log("Fail: current chain:",hre.network.name);
        return;
    }
    let deployer = await lib.getAddress('comd')

    let fwdDplatAddress = await lib.getAddress('ZbyteForwarderDPlat');
    SampleDstoreDapp = await hre.deployments.deploy(
        'SampleDstoreDapp', {
            from:deployer,
            args: [fwdDplatAddress],
            gasLimit: 6e6,
            deterministicDeployment: false
        })
    console.log('==SampleDstoreDapp addr=', SampleDstoreDapp.address);
}

module.exports = deployDapp