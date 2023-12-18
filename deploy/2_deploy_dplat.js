const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("../scripts/lib.js");
const fs = require("fs");

// TODO add fwd changes, vZbyte, dplat
async function deployDplat() {

    if(!(lib.isDplatChain())) {
        console.log("Fail: current chain:",hre.network.name);
        return;
    }
    let deployer = await lib.getAddress('zbyt')
    let burner = await lib.getAddress('burn')

    ZbyteForwarderDPlat = await hre.deployments.deploy(
        'ZbyteForwarderDPlat', {
            from:deployer,
            args: [],
            gasLimit: 6e6,
            deterministicDeployment: false
        })
    console.log('==ZbyteForwarderDPlat addr=', ZbyteForwarderDPlat.address);

    ZbyteVToken = await hre.deployments.deploy(
        'ZbyteVToken', {
            from:deployer,
            args: [burner],
            gasLimit: 6e6,
            deterministicDeployment: false
        })
    console.log('==ZbyteVToken addr=', ZbyteVToken.address);

    ZbyteRelay = await hre.deployments.deploy(
        'ZbyteRelay', {
            from:deployer,
            args: [ZbyteForwarderDPlat.address],
            gasLimit: 6e6,
            deterministicDeployment: false
        })
    console.log('==ZbyteRelay addr=', ZbyteRelay.address);

    ZbytePriceFeeder = await hre.deployments.deploy(
        'ZbytePriceFeeder', {
            from:deployer,
            args: [ZbyteForwarderDPlat.address],
            gasLimit: 6e6,
            deterministicDeployment: false
        })
    console.log('==ZbytePriceFeeder addr=', ZbytePriceFeeder.address);

    const zbyteDPlat = await hre.deployments.diamond.deploy(
        'ZbyteDPlat', {
            from:deployer,
            owner:deployer,
            gasLimit: 6e6,
            log: true,
            facets: ['ZbyteDPlatBaseFacet', 'ZbyteDPlatPaymentFacet', 'ZbyteDPlatRegistrationFacet', 'ZbyteForwarderFacet', 'ZbyteDPlatRoyaltyFacet']
        })
    console.log('==ZbyteDPlat addr=', zbyteDPlat.address);
}

module.exports = deployDplat