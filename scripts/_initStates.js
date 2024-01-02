const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("./lib.js");
const chai = require("chai");
const expect = chai.expect;

async function initCoreStates(owner) {
    if (!(lib.isCoreChain())) {
        console.log("Fail: current chain:",hre.network.name);
        return;
    }
    try {
        let retval = {};

        const fwdCore = require("./_zbyteForwarderCore.js");
        const escrow = require("./_zbyteEscrow.js");
        const relayWrapper = require("./_relayWrapper.js");
    
        let ret;
        console.log("  ZbyteForwarderCore set Zbyte Address & Escrow Address");
        ret = await fwdCore.setZbyteAddress(owner);
        retval["fwdN-setZbyteAddress"] = ret;
        ret = await fwdCore.setZbyteTokenForwarderAddress(owner);
        retval["fwdN-setZbyteTokenForwarderAddress"] = ret;
        ret = await fwdCore.setEscrowAddress(owner);
        retval["fwdN-setEscrowAddress"] = ret;
    
        console.log("          |------>");
        console.log(" Zbyte Escrow wrapper -- relay vZbyte");
        ret = await escrow.setRelayWrapperAddress(owner);
        retval["escrow-setRelayWrapper"] = ret;
    
        ret = await relayWrapper.setEscrowAddress(owner);
        retval["relayWrapper-setEscrowAddress"] = ret;

        ret = await escrow.registerWorker('zbyt', 'wrkr');
        retval["escrow-registerWorker"] = ret;

        return retval;
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function initCoreStateForDplat(owner,chain,relay) {
    if (!(lib.isCoreChain())) {
        console.log("Fail: current chain:",hre.network.name);
        return;
    }
    try {
        let retval = {};
        const escrow = require("./_zbyteEscrow.js");
        const relayWrapper = require("./_relayWrapper.js");
        const zbytePriceFeeder = require("./_zbytePriceFeeder.js");
    
        let ret;
        console.log("  RwlayWrapper ----> Relay");
        ret = await relayWrapper.setRelayAddress(owner,chain,relay);
        retval["relayWrapper-setRelayAddress"] = ret;

        console.log("  Escrow --|--> vERC20");
        ret = await escrow.setvERC20Address(owner,chain);
        retval["Escrow-setvERC20Address"] = ret;
        return retval;
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function initDplatStates(owner) {
    if (!(lib.isDplatChain())) {
        console.log("Fail: current chain:",hre.network.name);
        return;
    }
    try {
        let retval = {};

        const zbyteRelay = require("./_zbyteRelay.js");
        const zbyteVToken = require("./_zbyteVToken.js");
        const zbyteDPlat = require("./_zbyteDPlat.js");
        const zbyteFwdDPlat = require("./_zbyteForwarderDplat.js");
        const zbytePriceFeeder = require("./_zbytePriceFeeder.js");
    
        let ret;
        /*
            set fwd states
            set dplat states
            set vzbyte states
        */

        // set forwarder dplat states
        ret = await zbyteFwdDPlat.setMinProcessingGas('zbyt', 42000);
        retval["zbyteFwdDPlat-setMinProcessingGas"] = ret;

        ret = await zbyteFwdDPlat.setPostExecGas('zbyt', 70000);
        retval["zbyteFwdDPlat-setPostExecGas"] = ret;

        ret = await zbyteFwdDPlat.setZbyteDPlat('zbyt');
        retval["zbyteFwdDPlat-setZbyteDPlat"] = ret;

        ret = await zbyteFwdDPlat.registerWorker('zbyt', ['wrkr']);
        retval["zbyteFwdDPlat-registerWorker"] = ret;

        // set zbyte dplat states
        ret = await zbyteDPlat.setZbyteVToken('zbyt');
        retval["zbyteFwdDPlat-setZbyteVToken"] = ret;

        ret = await zbyteDPlat.setZbyteForwarderDPlat('zbyt');
        retval["zbyteFwdDPlat-setZbyteForwarderDPlat"] = ret;

        ret = await zbyteDPlat.setZbytePriceFeeder('zbyt');
        retval["zbyteFwdDPlat-setZbytePriceFeeder"] = ret;

        // zbyte relay set states
        ret = await zbyteRelay.addRelayApprovee('zbyt',owner);
        retval["zbyteRelay-addRelayApprovee"] = ret;

        if(lib.isCoreChain()) {
            // wrapper address is set only if it CORE and DPLAT are same chain
            ret = await zbyteRelay.setRelayWrapper(owner);
            retval["zbyteRelay-setRelayWrapper"] = ret;
        }

        // vzbyte set states
        ret = await zbyteVToken.setPaymasterAddress(owner);
        retval["zbyteVToken-setPaymasterAddress"] = ret;

        ret = await zbyteVToken.setRoleCapability(1,
            "mint(address to_, uint256 amount_) public returns(uint256)",
            true,'zbyt')
        retval["zbyteVToken-setRoleCapability"] = ret;
        ret = await zbyteVToken.setRoleCapability(1,
            "destroy(address from_) public returns(uint256)",
            true,'zbyt')
        retval["zbyteVToken-setRoleCapability"] = ret;

        ret = await zbyteVToken.setUserRole('ZbyteRelay',1,true,'zbyt')
        retval["zbyteVToken-setUserRole"] = ret;

        ret = await zbyteVToken.setRoleCapability(2,
            "transferFrom(address from_, address to_, uint256 value_) public returns (bool)", true,'zbyt')
        retval["zbyteVToken-setRoleCapability"] = ret;
        ret = await zbyteVToken.setRoleCapability(2,
            "burn(address from_, uint256 amount_) external returns(uint256)",
            true,'zbyt')
        retval["zbyteVToken-setRoleCapability"] = ret;

        ret = await zbyteVToken.setRoleCapability(2,
            "transfer(address from_, uint256 amount_) external returns(uint256)",
            true,'zbyt')
        retval["zbyteVToken-setRoleCapability"] = ret;

        ret = await zbyteVToken.setUserRole('ZbyteDPlat',2,true,'zbyt')
        retval["zbyteVToken-setUserRole"] = ret;

        ret = await zbyteVToken.setZbyteDPlatAddress(owner);
        retval["zbyteVToken-setZbyteDPlatAddress"] = ret;


        //zbytePriceFeeder states
        ret = await zbytePriceFeeder.registerWorker(owner,'wrkr');
        retval["zbytePriceFeeder-registerWorker"] = ret;

        ret = await zbytePriceFeeder.setNativeEthEquivalentZbyteInGwei('wrkr', "9000000000"); // 1L1=0.9$
        retval["zbytePriceFeeder-setNativeEthEquivalentZbyteInGwei"] = ret;

        ret = await zbytePriceFeeder.setZbytePriceInGwei('wrkr', "10000000000"); // 1DPLAT=0.1$
        retval["zbytePriceFeeder-setZbytePriceInGwei"] = ret;

        ret = await zbytePriceFeeder.setBurnRateInMill(owner, "20"); // burn=0.02$
        retval["zbytePriceFeeder-setBurnRateInMill"] = ret;

        return retval;
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function initDappStates(dapp, owner) {
    if (!(lib.isDplatChain())) {
        console.log("Fail: current chain:",hre.network.name);
        return;
    }
    try {
        let retval = {
            function: "initDappStates"
        };

        return retval;
    } catch (error) {
        console.log(error);
        throw(error);
    }
}

async function transferOwnership(cname, owner,newOwner) {
    try {
        let contractWithSigner = await lib.getContractWithSigner(cname, owner);

        let ownerAddress = await lib.getAddress(owner);
        let newOwnerAddress = await lib.getAddress(newOwner);
        console.log("transferOwnership: " + cname + "," + ownerAddress + "," + newOwnerAddress);
        const tx = await contractWithSigner.transferOwnership(newOwnerAddress);
        await expect(tx.wait())
                .to.emit(contractWithSigner,"OwnershipTransferred")
                .withArgs(ownerAddress,newOwnerAddress);
        return {function: "transferOwnership",
                prevowner: ownerAddress,
                newowner: newOwnerAddress}
    } catch (error) {
        console.log(error);
    }
}

module.exports = {
    initCoreStates: initCoreStates,
    initCoreStateForDplat:initCoreStateForDplat,
    initDplatStates:initDplatStates,
    initDappStates:initDappStates,
    transferOwnership:transferOwnership
}
