const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("../scripts/lib.js");
const chai = require("chai");
const execCmd = require("../scripts/_execCmd.js");
const expect = chai.expect;
const constants = require("../scripts/constants.js");

// TODO extract ack from all deposit/withdraw events and track it
// TODO vZbyte minter and relay approvee different from zbyt
// TODO ensure this can work with Axelar
async function eventListener() {
    let amount = 100; // amount for all deposit
    let zbyteRelayContract = await lib.getContract("ZbyteRelay");
    /*
        deposit (core) -> relayWrapper (core) -> relay.callRemote (core)
                                                    {RelayCallRemoteReceived}
                                                            *
                                                            *
                                                    <This script (part 1) 
                                                        catches this event on core &
                                                        invokes relay.receiveCall on dplat
                                                        ack != 0>
                                                            * 
                                                            *
                                                        relay.receiveCall(dplat)
                                                        [calls verc20.mint(user,amt)]
                                                        {RelayReceiveCallExecuted}
                                                        calls this.callRemote (to send ack)
                                                        {RelayCallRemoteReceived}
                                                            *
                                                            *
                                                    <This script (part 2)
                                                        catches this event on dplat &
                                                        relay.receiveCall on core
                                                        ack == 0>
                            relay.receiveCall (core)
                            [calls escrow.callbackhandler]
                            {RelayReceiveCallExecuted}
                            [NO FURTHER RelayCallRemoteReceived AS  ack=0]
                                        *
                                        *
                            <This script (part 3) >

        if hre.network.name == constants.core 
            core = hre.network.name
            dplat = event.destChainId
            if event == RelayCallRemoteReceived
                //part 1
                call receiveCall on dplat
            else if event = RelayReceiveCallExecuted
                // part 3
                // escrow state updated
        else if hre.network.name != core
            core = constants.core
            dplat = hre.network.name
            if event == RelayCallRemoteReceived
                // call receiveCall on core
    */
    zbyteRelayContract.on( "RelayCallRemoteReceived", 
    (srcChainId,srcRelay,destChainId,destRelay,payload) => {
    try {
        console.log(srcChainId,srcRelay,destChainId,destRelay,payload);
        let abiCoder = new ethers.AbiCoder();
        let decodedOutput = abiCoder.decode(['uint256','address','bytes32','address','bytes'],payload);
        console.log("RelayCallRemoteReceived",hre.network.name,decodedOutput);
        let ack = decodedOutput[2];
        let logDict = {}
        if (ack.toString() == '0x'+'0'.repeat(64)) {
            logDict[ack] = {
                "event":"RelayCallRemoteReceived",
                "chain":hre.network.name,
                "zeroAck":true,
                "cbData":decodedOutput[4]
            }
        } else {
            logDict[ack] = {
                "event":"RelayCallRemoteReceived",
                "chain":hre.network.name
            }
        }
        lib.logAck(logDict);

        if(hre.network.name == constants.core) {
            // Event on core
            if(lib.chainIdToName(srcChainId) != hre.network.name) {
                console.log("src chain is NOT current chain",lib.chainIdToName(srcChainId),hre.network.name)
            } else {
                let core = hre.network.name;
                let dplat = lib.chainIdToName(destChainId)
                if (core == dplat) {
                    console.log("src and dest is both core");
                } else {
                    // call zbyteRelay.receiveCall on dplat
                    const cmd = {
                        core: core, dplat: dplat,
                        task: 'zbyteRelay', runon: 'dplat', api: 'receiveCall',
                        srcch: core, srcrelay: srcRelay,
                        dstch: dplat, dstrelay:destRelay,
                        payload:payload, amount:amount,owner:'zbyt'
                    }
                    console.log(cmd)
                    execCmd.execCmd(cmd)
                    console.log("RelayCallRemoteReceived on  core -> receiveCall done on dplat")
                }
            }
        } else {
            // Event on dplat
            if(lib.chainIdToName(srcChainId) != hre.network.name) {
                console.log("src chain is NOT current chain",lib.chainIdToName(srcChainId),hre.network.name)
            } else {
                let core = constants.core;
                let dplat = lib.chainIdToName(srcChainId)
                if (core == dplat) {
                    console.log("src and dest is both dplat!");
                } else {
                    // call zbyteRelay.receiveCall on core
                    const cmd = {
                        core: core, dplat: dplat,
                        task: 'zbyteRelay', runon: 'core', api: 'receiveCall',
                        srcch: core, srcrelay: srcRelay,
                        dstch: dplat, dstrelay:destRelay,
                        payload:payload, amount:amount,owner:'zbyt'
                    }
                    console.log(cmd)
                    execCmd.execCmd(cmd)
                    console.log("RelayCallRemoteReceived on  dplat -> receiveCall done on core")
                }
            }
        }
    } catch (error) {
        console.log(error);
    }
    });

    
    zbyteRelayContract.on( "RelayReceiveCallExecuted", 
    (payload,success,retval) => {
    try {
        console.log(payload,success,retval);
        let abiCoder = new ethers.AbiCoder();
        let decodedOutput = abiCoder.decode(['uint256','address','bytes32','address','bytes'],payload);
        console.log("RelayReceiveCallExecuted",hre.network.name,decodedOutput);
        let ack = decodedOutput[2];
        let logDict = {}
        logDict[ack] = {
            "event":"RelayReceiveCallExecuted",
            "chain":hre.network.name,
            "result":success,
            "return":retval.toString()
        }
        lib.logAck(logDict);
    } catch (error) {
        console.log(error);
    }
    });
}

(async () => {
    await eventListener();
})();