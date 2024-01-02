const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("../scripts/lib.js");
const fs = require("fs");

async function deployCore() {

    if(!(lib.isCoreChain())) {
        console.log("Fail: current chain:",hre.network.name);
        return;
    }
    let deployer = await lib.getAddress('zbyt')
    let treasury = await lib.getAddress('burn')

    ZbyteForwarderCore = await hre.deployments.deploy(
        'ZbyteForwarderCore', {
            from:deployer,
            args: [],
            gasLimit: 6e6,
            deterministicDeployment: false
        })
    console.log('==ZbyteForwarderCore addr=', ZbyteForwarderCore.address);

    let ZbyteTokenAddress = await lib.getAddress('ZbyteToken')
    ZbyteEscrow = await hre.deployments.deploy(
        'ZbyteEscrow', {
            from:deployer,
            args: [ZbyteForwarderCore.address,ZbyteTokenAddress],
            gasLimit: 6e6,
            deterministicDeployment: false
        })
    console.log('==ZbyteEscrow addr=', ZbyteEscrow.address);

    RelayWrapper = await hre.deployments.deploy(
        'RelayWrapper', {
            from:deployer,
            args: [ZbyteForwarderCore.address],
            gasLimit: 6e6,
            deterministicDeployment: false
        })
    console.log('==RelayWrapper addr=', RelayWrapper.address);
    return {
        function: "deployCore"
    }
}

module.exports = deployCore
