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
    else if(dapp == "ZbyteAirdropNFT") {
        let deployer = await lib.getAddress(depl);
        ZbyteDUSDT = await hre.deployments.deploy(
            'ZbyteDUSDT', {
                from:deployer,
                args: [],
                gasLimit: 6e6,
                deterministicDeployment: false
            })
        console.log('==ZbyteDUSDT addr=', ZbyteDUSDT.address);

        let dusdtAddress = ZbyteDUSDT.address;
        let dusdtPerToken = ethers.parseUnits('1',18); // change for mainnet
        let distributorAddress = await lib.getAddress('prov'); 
        ZbyteAirdropNFT = await hre.deployments.deploy(
            'ZbyteAirdropNFT', {
                from:deployer,
                args: [dusdtAddress,dusdtPerToken,
                            distributorAddress,"https://zbyte.io/"],
                gasLimit: 6e6,
                deterministicDeployment: false
            })
        console.log('==ZbyteAirdropNFT addr=', ZbyteAirdropNFT.address);
        ret = {
            function:"deployDapp",
            dapp: dapp,
            dappAddress: ZbyteAirdropNFT.address,
            deployer: deployer
        }
    } else if(dapp == "ZbyteStaking") {
        let deployer = await lib.getAddress(depl);
        ZbyteDUSDT = await hre.deployments.deploy(
            'ZbyteDUSDT', {
                from:deployer,
                args: [],
                gasLimit: 6e6,
                deterministicDeployment: false
            })
        console.log('==ZbyteDUSDT addr=', ZbyteDUSDT.address);

        let dusdtAddress = ZbyteDUSDT.address;
        let dplatTokenAddress = await lib.getAddress('ZbyteToken');
        ZbyteStaking = await hre.deployments.deploy(
            'ZbyteStaking', {
                from:deployer,
                args: [dusdtAddress,dplatTokenAddress ],
                gasLimit: 6e6,
                deterministicDeployment: false
            })
        console.log('==ZbyteStaking addr=', ZbyteStaking.address);
        ret = {
            function:"deployDapp",
            dapp: dapp,
            dappAddress: ZbyteStaking.address,
            deployer: deployer
        }
    }
    return ret;
}

module.exports = deployDapp
