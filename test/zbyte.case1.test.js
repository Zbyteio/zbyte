const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("../scripts/lib.js");
const chai = require("chai");
const expect = chai.expect;
const fs = require('fs');
const constants = require('../scripts/constants.js')

/// Contracts
const dplatFwd = "ZbyteForwarderDPlat";
const dplat = "ZbyteDPlat";

/// Events
const dplatFwdExecuteResult = "ZbyteForwarderDPlatExecute";
const preExecFees = "PreExecFees";
const postExecFees = "PostExecFees";

function verifyResult(expected,result) {
    if (result == undefined) {
        return false;
    }
    keys = Object.keys(expected)
    for(var i=0; i < keys.length; i++) {
      if(result[keys[i]] != expected[keys[i]]) {
        return false;
      }
    }
    return true;
}

async function readBalances(accounts) {
    bal = {}
    accounts = accounts.concat(['ZbyteForwarderDPlat','wrkr','burn']);
    for(var i=0; i<accounts.length;i++) {
        const zbyteToken = require("../scripts/_zbyteToken.js")
        retval = await zbyteToken.balanceOf(accounts[i]);
        bal[accounts[i]] = {'balZ': retval.balZ, 'balL1':retval.balL1}
        const zbyteVToken = require("../scripts/_zbyteVToken.js")
        retval = await zbyteVToken.balanceOf(accounts[i]);
        bal[accounts[i]]['balVZ'] = retval.balZ;
    }
    return bal;
}

async function verifyEventData(txHash, contractName, eventName, expectedEventData) {
    var actualEventData = await lib.parseSpecificEvent(txHash, contractName, eventName);
    console.log("verifyEventData: ", txHash, contractName, eventName, expectedEventData, actualEventData, expectedEventData.length, actualEventData.length);

    expect(actualEventData.length).to.eq(expectedEventData.length);
    for (var i = 0; i < actualEventData.length; i++) {
        expect(actualEventData[i]).to.eq(expectedEventData[i]);
    }
}

describe("Zbyte case1 test", function () {
    /* deployer deploys dapp, invoker invokes fnnameWrite and pays L1 */
    const dapp = 'SampleDstoreDapp'
    const deployer = 'comd'
    const invoker = 'comu'
    const fnnameWrite = 'storeValue'
    const fnWriteparam = "10";
    const fnnameVerify = 'storedValue'
    const fnVerifyParam = "0x000000000000000000000000000000000000000000000000000000000000000a"
    
    before(async function () {
    })
    it("deploy Dapp", async function () {
        const deployDapp = require("../deploy/3_deploy_dapp.js");
        retval = await deployDapp(dapp, deployer);
        expect(verifyResult({function:"deployDapp",dapp: dapp}, retval)).to.eq(true);
    })
    it("init Dapp States", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        retval = await invokeDapp.setTrustedForwarder(dapp,deployer,'ZbyteForwarderDPlat');
        expect(verifyResult({function:"setTrustedForwarder"}, retval)).to.eq(true);
        const initDapp = require("../scripts/_initStates.js");
        retval = await initDapp.initDappStates(dapp, deployer);
        expect(verifyResult({function:"initDappStates"}, retval)).to.eq(true);
    })
    it("store value", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        var balancesBefore = await readBalances([deployer,invoker])
        retval = await invokeDapp.invoke(dapp, invoker, fnnameWrite, fnWriteparam);    
        expect(verifyResult({function:"invoke", dapp: await lib.getAddress(dapp)}, retval)).to.eq(true);
        var balancesAfter = await readBalances([deployer,invoker])
        expect(Number(balancesBefore[invoker]['balL1'])).to.greaterThan(Number(balancesAfter[invoker]['balL1']));
        expect(balancesBefore[deployer]['balL1']).to.eq(balancesAfter[deployer]['balL1']);
    })
    it("read value", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        retval = await invokeDapp.invokeView(dapp, fnnameVerify);    
        expect(verifyResult({function:"invokeView", dapp: await lib.getAddress(dapp),
                    result:fnVerifyParam}, retval)).to.eq(true);
    })
})

/* deployer deploys dapp, invoker invokes fnnameWrite via ZbyteFwdDPlat but does not have vZBYT 
        call fails
*/
describe("Zbyte case2 test", function () {

    const dapp = 'SampleDstoreDapp'
    const deployer = 'comd'
    const invoker = 'comu'
    const fnnameWrite = 'storeValue'
    const fnWriteparam = "11";
    const fnnameVerify = 'storedValue'
    const fnVerifyParam = "0x000000000000000000000000000000000000000000000000000000000000000a"
    
    before(async function () {
    })
    it("deploy Dapp", async function () {
        const deployDapp = require("../deploy/3_deploy_dapp.js");
        retval = await deployDapp(dapp, deployer);
        expect(verifyResult({function:"deployDapp",dapp: dapp}, retval)).to.eq(true);
    })
    it("init Dapp States", async function () {
    })
    it("store value", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        var balancesBefore = await readBalances([deployer,invoker])
        retval = await invokeDapp.invokeViaForwarder(dapp, invoker,fnnameWrite, fnWriteparam);

        // fails as comu does not have vZBYT
        expect(verifyResult({function:"invoke", dapp: await lib.getAddress(dapp)}, retval)).to.eq(false);
        var balancesAfter = await readBalances([deployer,invoker])
        expect(balancesBefore[invoker]['balL1']).to.eq(balancesAfter[invoker]['balL1']);
        expect(balancesBefore[deployer]['balL1']).to.eq(balancesAfter[deployer]['balL1']);
    })
    it("read value", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        retval = await invokeDapp.invokeView(dapp, fnnameVerify);    
        expect(verifyResult({function:"invokeView", dapp: await lib.getAddress(dapp),
                    result:fnVerifyParam}, retval)).to.eq(true);
    })
})

/* deployer deploys dapp, invoker invokes fnnameWrite via ZbyteFwdDPlat and pays in vZBYT
        Dapp is from opensource user, Dapp not registered with DPlat.  Fwd in dapp should be ZbyteForwarderDPlat
        User is opensource, calls Dapp and pays in DPLAT
*/
describe("Zbyte case3 test", function () {

    const dapp = 'SampleDstoreDapp'
    const deployer = 'comd'
    const invoker = 'comu'
    const fnnameWrite = 'storeValue'
    const fnWriteparam = "11";
    const fnnameVerify = 'storedValue'
    const fnVerifyParam = "0x000000000000000000000000000000000000000000000000000000000000000b"

    const relay = "ZbyteRelay"
    const sender = 'zbyt'
    const receiver = invoker;
    const amount = "100"
    const worker = 'wrkr'
    
    before(async function () {
    })
    it("deploy Dapp", async function () {
        const deployDapp = require("../deploy/3_deploy_dapp.js");
        retval = await deployDapp(dapp, deployer);
        expect(verifyResult({function:"deployDapp",dapp: dapp}, retval)).to.eq(true);
    })
    it("init Dapp States", async function () {
    })
    it("deposit vZBYT for comu", async function () {
        const zbyteFwdCore = require("../scripts/_zbyteForwarderCore.js")
        const dplatChain = process.env.DPLAT
        retval = await zbyteFwdCore.approveAndDeposit(relay,sender,
                receiver,amount,dplatChain,worker);
        expect(verifyResult({function:"approveAndDeposit"}, retval)).to.eq(true);
        var balances = await readBalances([deployer,invoker])
        expect(Number(balances[invoker]['balVZ'])).to.greaterThanOrEqual(Number(amount));
    })
    it("store value", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        const priceFeeder = require("../scripts/_zbytePriceFeeder.js");
        var balancesBefore = await readBalances([deployer,invoker,'ZbyteDPlat',worker])
        retval = await invokeDapp.invokeViaForwarder(dapp, invoker,fnnameWrite, fnWriteparam);
        // fails as comu does not have vZBYT
        expect(verifyResult({function:"invokeViaForwarder", dapp: await lib.getAddress(dapp)}, retval)).to.eq(true);
        var balancesAfter = await readBalances([deployer,invoker,'ZbyteDPlat',worker])
        // L1: only wrkr l1 should reduce
        // vZ: tokens reduced in comu = sum of tokens added to burn and fwdDplat
        expect(balancesBefore[invoker]['balL1']).to.eq(balancesAfter[invoker]['balL1']);
        expect(balancesBefore[deployer]['balL1']).to.eq(balancesAfter[deployer]['balL1']);

        // invokerZbyteOut = fwdZbyteIn+burnZbyteIn
        var invokerZbyteOut = ethers.toBigInt(ethers.parseUnits(balancesBefore[invoker]['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesAfter[invoker]['balVZ'],18))
        var fwdZbyteIn = ethers.toBigInt(ethers.parseUnits(balancesAfter['ZbyteForwarderDPlat']['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesBefore['ZbyteForwarderDPlat']['balVZ'],18))
        var burnZbyteIn = ethers.toBigInt(ethers.parseUnits(balancesAfter['burn']['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesBefore['burn']['balVZ'],18))
        expect(invokerZbyteOut).eq(fwdZbyteIn+burnZbyteIn);

        // toZbyte(workerL1Out) >= invokerZbyteOut
        const feeData = await ethers.provider.getFeeData()
        var workerL1Out = ethers.toBigInt(ethers.parseUnits(balancesBefore[worker]['balL1'],18))
            -ethers.toBigInt(ethers.parseUnits(balancesAfter[worker]['balL1'],18))
        var workerZbyteOut = (await priceFeeder.convertEthToEquivalentZbyte(workerL1Out)).value;
        expect(workerZbyteOut).lessThanOrEqual(invokerZbyteOut);
        console.log("Worker Gain%",(fwdZbyteIn - workerZbyteOut) * BigInt(100) / workerZbyteOut);
    })
    it("read value", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        retval = await invokeDapp.invokeView(dapp, fnnameVerify);    
        expect(verifyResult({function:"invokeView", dapp: await lib.getAddress(dapp),
                    result:fnVerifyParam}, retval)).to.eq(true);
    })
})

/* deployer deploys dapp, invoker invokes fnnameWrite via ZbyteFwdDPlat
        Dapp is from opensource user, Fwd in dapp should be ZbyteForwarderDPlat
        deployer registers dapp with DPlat, creates provider, enterprise, etc
        User is opensource, calls Dapp.
        deployer's provider pays for the call in DPLAT
*/
describe("Zbyte case4 test", function () {
    /* deployer deploys dapp, invoker invokes fnnameWrite via ZbyteFwdDPlat. deployer pays for all calls in vZBYT */
    const dapp = 'SampleDstoreDapp'
    const deployer = 'comd'
    const invoker = 'comu'
    const fnnameWrite = 'storeValue'
    const fnWriteparam = "12";
    const fnnameVerify = 'storedValue'
    const fnVerifyParam = "0x000000000000000000000000000000000000000000000000000000000000000c"

    const relay = "ZbyteRelay"
    const sender = 'zbyt'
    const receiver = deployer;
    const amount = "100"
    const worker = 'wrkr'
    
    before(async function () {
    })
    it("deploy Dapp", async function () {
        const deployDapp = require("../deploy/3_deploy_dapp.js");
        retval = await deployDapp(dapp, deployer);
        expect(verifyResult({function:"deployDapp",dapp: dapp}, retval)).to.eq(true);
    })
    it("init Dapp States", async function () {
    })
    it("deposit vZBYT for comd", async function () {
        const zbyteFwdCore = require("../scripts/_zbyteForwarderCore.js")
        const dplatChain = process.env.DPLAT
        retval = await zbyteFwdCore.approveAndDeposit(relay,sender,
                receiver,amount,dplatChain,worker);
        expect(verifyResult({function:"approveAndDeposit"}, retval)).to.eq(true);
        var balances = await readBalances([deployer,invoker])
        expect(ethers.toBigInt(ethers.parseUnits(balances[receiver]['balVZ'],18)))
            .to.greaterThanOrEqual(ethers.toBigInt(ethers.parseUnits(amount,18)));
    })

    it("set the deployer as payer", async function () {
        const zbyteDPlat = require("../scripts/_zbyteDPlat.js")
        await zbyteDPlat.registerProvider(deployer);
        // await zbyteDPlat.registerProviderAgent(deployer,deployer);
        await zbyteDPlat.registerEnterprise(deployer, "community dev");
        await zbyteDPlat.registerEnterpriseUser(deployer,'comu',"community dev");
        await zbyteDPlat.setEnterpriseLimit(deployer,"community dev",amount);
    })

    it("store value com user open source dapp", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        const priceFeeder = require("../scripts/_zbytePriceFeeder.js");
        const zbyteDPlat = require("../scripts/_zbyteDPlat.js")

        const ret = await zbyteDPlat.getPayer('comu','SampleDstoreDapp',
            'storeValue','10');
        expect(ret.provider).to.eq(await lib.getAddress('comd'));

        var balancesBefore = await readBalances([deployer,invoker,'ZbyteDPlat',worker])
        retval = await invokeDapp.invokeViaForwarder(dapp, invoker,fnnameWrite, fnWriteparam);

        expect(verifyResult({function:"invokeViaForwarder", dapp: await lib.getAddress(dapp)}, retval)).to.eq(true);
        var balancesAfter = await readBalances([deployer,invoker,'ZbyteDPlat',worker])
        // L1: only wrkr l1 should reduce
        // vZ: tokens reduced in comd = sum of tokens added to burn and fwdDplat
        expect(balancesBefore[invoker]['balL1']).to.eq(balancesAfter[invoker]['balL1']);
        expect(balancesBefore[invoker]['balVZ']).to.eq(balancesAfter[invoker]['balVZ']);
        expect(balancesBefore[deployer]['balL1']).to.eq(balancesAfter[deployer]['balL1']);

        // deployerZbyteOut = fwdZbyteIn+burnZbyteIn
        var deployerZbyteOut = ethers.toBigInt(ethers.parseUnits(balancesBefore[deployer]['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesAfter[deployer]['balVZ'],18))
        var fwdZbyteIn = ethers.toBigInt(ethers.parseUnits(balancesAfter['ZbyteForwarderDPlat']['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesBefore['ZbyteForwarderDPlat']['balVZ'],18))
        var burnZbyteIn = ethers.toBigInt(ethers.parseUnits(balancesAfter['burn']['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesBefore['burn']['balVZ'],18))
        console.log(deployerZbyteOut,fwdZbyteIn,burnZbyteIn);
        expect(deployerZbyteOut).eq(fwdZbyteIn+burnZbyteIn);

        // toZbyte(workerL1Out) >= deployerrZbyteOut
        const feeData = await ethers.provider.getFeeData()
        var workerL1Out = ethers.toBigInt(ethers.parseUnits(balancesBefore[worker]['balL1'],18))
            -ethers.toBigInt(ethers.parseUnits(balancesAfter[worker]['balL1'],18))
        var workerZbyteOut = (await priceFeeder.convertEthToEquivalentZbyte(workerL1Out)).value;
        console.log("workerZbyteOut: ", workerZbyteOut);
        expect(workerZbyteOut).lessThanOrEqual(deployerZbyteOut);
        console.log("Worker Gain%",(fwdZbyteIn - workerZbyteOut) * BigInt(100) / workerZbyteOut);
    })
    it("read value", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        retval = await invokeDapp.invokeView(dapp, fnnameVerify);    
        expect(verifyResult({function:"invokeView", dapp: await lib.getAddress(dapp),
                    result:fnVerifyParam}, retval)).to.eq(true);
    })
})


/* Enterprise deployer deploys dapp, invoker invokes fnnameWrite via ZbyteFwdDPlat
        Dapp is from ent user, Fwd in dapp should be ZbyteForwarderDPlat
        enterprise, provider is created.
        dapp is registered to the enterprise.
        User is opensource, calls Dapp.
        dapp's ent provider pays for the call in DPLAT
*/
describe("Zbyte case5 test", function () {
    const dapp = 'SampleDstoreDapp'
    const deployer = 'entd'
    const invoker = 'comu'
    const fnnameWrite = 'storeValue'
    const fnWriteparam = "13";
    const fnnameVerify = 'storedValue'
    const fnVerifyParam = "0x000000000000000000000000000000000000000000000000000000000000000d"
    const relay = "ZbyteRelay"

    const ent = "ABC Enterprise"
    const entProvider = 'entp'
    const sender = 'zbyt'
    const receiver = entProvider;
    const amount = "100"
    const worker = 'wrkr'
    
    before(async function () {
    })
    it("deploy Dapp", async function () {
        const deployDapp = require("../deploy/3_deploy_dapp.js");
        retval = await deployDapp(dapp, deployer);
        expect(verifyResult({function:"deployDapp",dapp: dapp}, retval)).to.eq(true);
    })
    it("init Dapp States", async function () {
    })
    it("deposit vZBYT for entp", async function () {
        const zbyteFwdCore = require("../scripts/_zbyteForwarderCore.js")
        const dplatChain = process.env.DPLAT
        retval = await zbyteFwdCore.approveAndDeposit(relay,sender,
            entProvider,amount,dplatChain,worker);
        expect(verifyResult({function:"approveAndDeposit"}, retval)).to.eq(true);
        var balances = await readBalances([entProvider,invoker])
        expect(ethers.toBigInt(ethers.parseUnits(balances[entProvider]['balVZ'],18)))
            .to.greaterThanOrEqual(ethers.toBigInt(ethers.parseUnits(amount,18)));
    })
    it("register enterprise provider and enterprise", async function () {
        const zbyteDPlat = require("../scripts/_zbyteDPlat.js")
        await zbyteDPlat.registerProvider(entProvider);
        //await zbyteDPlat.registerProviderAgent(deployer,deployer);
        await zbyteDPlat.registerEnterprise(entProvider,ent);
        await zbyteDPlat.registerDapp(entProvider,dapp,ent);
        await zbyteDPlat.setEnterpriseLimit(entProvider,ent,amount);
    })
    it("store value", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        const priceFeeder = require("../scripts/_zbytePriceFeeder.js");
        const zbyteDPlat = require("../scripts/_zbyteDPlat.js")

        const ret = await zbyteDPlat.getPayer(invoker,dapp,
        fnnameWrite,fnWriteparam);
        expect(ret.provider).to.eq(await lib.getAddress(entProvider));

        var balancesBefore = await readBalances([entProvider,invoker,'ZbyteDPlat',worker])
        retval = await invokeDapp.invokeViaForwarder(dapp, invoker,fnnameWrite, fnWriteparam);

        expect(verifyResult({function:"invokeViaForwarder", dapp: await lib.getAddress(dapp)}, retval)).to.eq(true);
        var balancesAfter = await readBalances([entProvider,invoker,'ZbyteDPlat',worker])
        // L1: only wrkr l1 should reduce
        // vZ: tokens reduced in comd = sum of tokens added to burn and fwdDplat
        expect(balancesBefore[invoker]['balL1']).to.eq(balancesAfter[invoker]['balL1']);
        expect(balancesBefore[entProvider]['balL1']).to.eq(balancesAfter[entProvider]['balL1']);

        // deployerZbyteOut = fwdZbyteIn+burnZbyteIn
        var entProviderZbyteOut = ethers.toBigInt(ethers.parseUnits(balancesBefore[entProvider]['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesAfter[entProvider]['balVZ'],18))
        var fwdZbyteIn = ethers.toBigInt(ethers.parseUnits(balancesAfter['ZbyteForwarderDPlat']['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesBefore['ZbyteForwarderDPlat']['balVZ'],18))
        var burnZbyteIn = ethers.toBigInt(ethers.parseUnits(balancesAfter['burn']['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesBefore['burn']['balVZ'],18))
        console.log(entProviderZbyteOut,fwdZbyteIn,burnZbyteIn)
        expect(entProviderZbyteOut).eq(fwdZbyteIn+burnZbyteIn);

        // toZbyte(workerL1Out) >= deployerrZbyteOut
        const feeData = await ethers.provider.getFeeData()
        var workerL1Out = ethers.toBigInt(ethers.parseUnits(balancesBefore[worker]['balL1'],18))
            -ethers.toBigInt(ethers.parseUnits(balancesAfter[worker]['balL1'],18))
        var workerZbyteOut = (await priceFeeder.convertEthToEquivalentZbyte(workerL1Out)).value;
        console.log("workerZbyteOut: ", workerZbyteOut);
        expect(workerZbyteOut).lessThanOrEqual(entProviderZbyteOut);
        console.log("Worker Gain%",(fwdZbyteIn - workerZbyteOut) * BigInt(100) / workerZbyteOut);
    })
    it("read value", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        retval = await invokeDapp.invokeView(dapp, fnnameVerify);    
        expect(verifyResult({function:"invokeView", dapp: await lib.getAddress(dapp),
                    result:fnVerifyParam}, retval)).to.eq(true);
    })
})


/* Enterprise deployer deploys dapp, invoker invokes fnnameWrite via ZbyteFwdDPlat
        Dapp is from ent user, Fwd in dapp should be ZbyteForwarderDPlat
        dapp is deregistered from ent
        User is opensource, calls Dapp. user pays in DPLAT
*/
describe("Zbyte case6 test", function () {
    const dapp = 'SampleDstoreDapp'
    const deployer = 'entd'
    const invoker = 'comu'
    const fnnameWrite = 'storeValue'
    const fnWriteparam = "14";
    const fnnameVerify = 'storedValue'
    const fnVerifyParam = "0x000000000000000000000000000000000000000000000000000000000000000e"
    const relay = "ZbyteRelay"

    const ent = "ABC Enterprise"
    const entProvider = 'entp'
    const sender = 'zbyt'
    const receiver = entProvider;
    const amount = "100"
    const worker = 'wrkr'
    
    before(async function () {
    })
    it("deploy Dapp", async function () {
    })
    it("init Dapp States", async function () {
    })
    it("deposit vZBYT for entp", async function () {
        const zbyteFwdCore = require("../scripts/_zbyteForwarderCore.js")
        const dplatChain = process.env.DPLAT
        retval = await zbyteFwdCore.approveAndDeposit(relay,sender,
            entProvider,amount,dplatChain,worker);
        expect(verifyResult({function:"approveAndDeposit"}, retval)).to.eq(true);
        var balances = await readBalances([entProvider,invoker])
        expect(ethers.toBigInt(ethers.parseUnits(balances[entProvider]['balVZ'],18)))
            .to.greaterThanOrEqual(ethers.toBigInt(ethers.parseUnits(amount,18)));
    })
    it("unregister dapp", async function () {
        const zbyteDPlat = require("../scripts/_zbyteDPlat.js")
        await zbyteDPlat.deregisterDapp(entProvider,dapp);
        await zbyteDPlat.deregisterEnterpriseUser('comd','comu');
    })
    it("store value", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        const priceFeeder = require("../scripts/_zbytePriceFeeder.js");
        const zbyteDPlat = require("../scripts/_zbyteDPlat.js")

        const ret = await zbyteDPlat.getPayer(invoker,dapp,
        fnnameWrite,fnWriteparam);
        expect(ret.provider).to.eq(await lib.getAddress(invoker));

        var balancesBefore = await readBalances([entProvider,invoker,'ZbyteDPlat',worker])
        retval = await invokeDapp.invokeViaForwarder(dapp, invoker,fnnameWrite, fnWriteparam);

        expect(verifyResult({function:"invokeViaForwarder", dapp: await lib.getAddress(dapp)}, retval)).to.eq(true);
        var balancesAfter = await readBalances([entProvider,invoker,'ZbyteDPlat',worker])
        // L1: only wrkr l1 should reduce
        // vZ: tokens reduced in comd = sum of tokens added to burn and fwdDplat
        expect(balancesBefore[invoker]['balL1']).to.eq(balancesAfter[invoker]['balL1']);
        expect(balancesBefore[entProvider]['balL1']).to.eq(balancesAfter[entProvider]['balL1']);

        // deployerZbyteOut = fwdZbyteIn+burnZbyteIn
        var invokerZbyteOut = ethers.toBigInt(ethers.parseUnits(balancesBefore[invoker]['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesAfter[invoker]['balVZ'],18))
        var fwdZbyteIn = ethers.toBigInt(ethers.parseUnits(balancesAfter['ZbyteForwarderDPlat']['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesBefore['ZbyteForwarderDPlat']['balVZ'],18))
        var burnZbyteIn = ethers.toBigInt(ethers.parseUnits(balancesAfter['burn']['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesBefore['burn']['balVZ'],18))
        console.log(invokerZbyteOut,fwdZbyteIn,burnZbyteIn)
        expect(invokerZbyteOut).eq(fwdZbyteIn+burnZbyteIn);

        // toZbyte(workerL1Out) >= deployerrZbyteOut
        const feeData = await ethers.provider.getFeeData()
        var workerL1Out = ethers.toBigInt(ethers.parseUnits(balancesBefore[worker]['balL1'],18))
            -ethers.toBigInt(ethers.parseUnits(balancesAfter[worker]['balL1'],18))
        var workerZbyteOut = (await priceFeeder.convertEthToEquivalentZbyte(workerL1Out)).value;
        console.log("workerZbyteOut: ", workerZbyteOut);
        expect(workerZbyteOut).lessThanOrEqual(invokerZbyteOut);
        console.log("Worker Gain%",(fwdZbyteIn - workerZbyteOut) * BigInt(100) / workerZbyteOut);
    })
    it("read value", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        retval = await invokeDapp.invokeView(dapp, fnnameVerify);    
        expect(verifyResult({function:"invokeView", dapp: await lib.getAddress(dapp),
                    result:fnVerifyParam}, retval)).to.eq(true);
    })
})

/* Enterprise deployer deploys dapp, invoker invokes fnnameWrite via ZbyteFwdDPlat
        Dapp is from ent user, Fwd in dapp should be ZbyteForwarderDPlat
        user is ent user, dapp's ent provider pays for the call in DPLAT
*/
describe("Zbyte case7 test", function () {
    const dapp = 'SampleDstoreDapp'
    const invoker = 'entd'
    const fnnameWrite = 'storeValue'
    const fnWriteparam = "15";
    const fnnameVerify = 'storedValue'
    const fnVerifyParam = "0x000000000000000000000000000000000000000000000000000000000000000f"
    const relay = "ZbyteRelay"

    const ent = "ABC Enterprise"
    const entProvider = 'entp'
    const sender = 'zbyt'
    const receiver = entProvider;
    const amount = "100"
    const worker = 'wrkr'
    
    before(async function () {
    })
    it("deploy Dapp", async function () {
    })
    it("init Dapp States", async function () {
    })
    it("deposit vZBYT for entp", async function () {
        const zbyteFwdCore = require("../scripts/_zbyteForwarderCore.js")
        const dplatChain = process.env.DPLAT
        retval = await zbyteFwdCore.approveAndDeposit(relay,sender,
            entProvider,amount,dplatChain,worker);
        expect(verifyResult({function:"approveAndDeposit"}, retval)).to.eq(true);
        var balances = await readBalances([entProvider,invoker])
        expect(ethers.toBigInt(ethers.parseUnits(balances[entProvider]['balVZ'],18)))
            .to.greaterThanOrEqual(ethers.toBigInt(ethers.parseUnits(amount,18)));
    })
    it("register entd", async function () {
        const zbyteDPlat = require("../scripts/_zbyteDPlat.js")
        await zbyteDPlat.registerEnterpriseUser(entProvider,invoker,ent);
    })
    it("store value", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        const priceFeeder = require("../scripts/_zbytePriceFeeder.js");
        const zbyteDPlat = require("../scripts/_zbyteDPlat.js")

        const ret = await zbyteDPlat.getPayer(invoker,dapp,
        fnnameWrite,fnWriteparam);
        expect(ret.provider).to.eq(await lib.getAddress(entProvider));

        var balancesBefore = await readBalances([entProvider,invoker,'ZbyteDPlat',worker])
        retval = await invokeDapp.invokeViaForwarder(dapp, invoker,fnnameWrite, fnWriteparam);

        expect(verifyResult({function:"invokeViaForwarder", dapp: await lib.getAddress(dapp)}, retval)).to.eq(true);
        var balancesAfter = await readBalances([entProvider,invoker,'ZbyteDPlat',worker])
        // L1: only wrkr l1 should reduce
        // vZ: tokens reduced in comd = sum of tokens added to burn and fwdDplat
        expect(balancesBefore[invoker]['balL1']).to.eq(balancesAfter[invoker]['balL1']);
        expect(balancesBefore[entProvider]['balL1']).to.eq(balancesAfter[entProvider]['balL1']);

        // deployerZbyteOut = fwdZbyteIn+burnZbyteIn
        var entProviderZbyteOut = ethers.toBigInt(ethers.parseUnits(balancesBefore[entProvider]['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesAfter[entProvider]['balVZ'],18))
        var fwdZbyteIn = ethers.toBigInt(ethers.parseUnits(balancesAfter['ZbyteForwarderDPlat']['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesBefore['ZbyteForwarderDPlat']['balVZ'],18))
        var burnZbyteIn = ethers.toBigInt(ethers.parseUnits(balancesAfter['burn']['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesBefore['burn']['balVZ'],18))
        console.log(entProviderZbyteOut,fwdZbyteIn,burnZbyteIn)
        expect(entProviderZbyteOut).eq(fwdZbyteIn+burnZbyteIn);

        // toZbyte(workerL1Out) >= deployerrZbyteOut
        const feeData = await ethers.provider.getFeeData()
        var workerL1Out = ethers.toBigInt(ethers.parseUnits(balancesBefore[worker]['balL1'],18))
            -ethers.toBigInt(ethers.parseUnits(balancesAfter[worker]['balL1'],18))
        var workerZbyteOut = (await priceFeeder.convertEthToEquivalentZbyte(workerL1Out)).value;
        console.log("workerZbyteOut: ", workerZbyteOut);
        expect(workerZbyteOut).lessThanOrEqual(entProviderZbyteOut);
        console.log("Worker Gain%",(fwdZbyteIn - workerZbyteOut) * BigInt(100) / workerZbyteOut);
    })
    it("read value", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        retval = await invokeDapp.invokeView(dapp, fnnameVerify);    
        expect(verifyResult({function:"invokeView", dapp: await lib.getAddress(dapp),
                    result:fnVerifyParam}, retval)).to.eq(true);
    })
})


describe("Zbyte getPayer test", function () {

    const dapp = 'SampleDstoreDapp'
    const deployer = 'comd'
    const invoker = 'entd'
    const fnnameWrite = 'storeValue'
    const fnWriteparam = "13";
    const fnnameVerify = 'storedValue'
    const fnVerifyParam = "0x000000000000000000000000000000000000000000000000000000000000000d"

    const relay = "ZbyteRelay"
    const sender = 'zbyt'
    const receiver = deployer;
    const amount = "100"
    const worker = 'wrkr'
    
    before(async function () {
    })
    it("deploy Dapp", async function () {
        const deployDapp = require("../deploy/3_deploy_dapp.js");
        retval = await deployDapp(dapp, deployer);
        expect(verifyResult({function:"deployDapp",dapp: dapp}, retval)).to.eq(true);
    })
    it("init Dapp States", async function () {
    })
    it("deposit vZBYT for comd", async function () {
        const zbyteFwdCore = require("../scripts/_zbyteForwarderCore.js")
        const dplatChain = process.env.DPLAT
        retval = await zbyteFwdCore.approveAndDeposit(relay,sender,
                receiver,amount,dplatChain,worker);
        expect(verifyResult({function:"approveAndDeposit"}, retval)).to.eq(true);
        var balances = await readBalances([deployer,invoker])
        expect(ethers.toBigInt(ethers.parseUnits(balances[receiver]['balVZ'],18)))
            .to.greaterThanOrEqual(ethers.toBigInt(ethers.parseUnits(amount,18)));
    })

    it("set the deployer as payer", async function () {
        const zbyteDPlat = require("../scripts/_zbyteDPlat.js")
        await zbyteDPlat.registerDapp(deployer,'SampleDstoreDapp','community dev');
    })

    it("store value ent user open source dapp", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        const priceFeeder = require("../scripts/_zbytePriceFeeder.js");
        const zbyteDPlat = require("../scripts/_zbyteDPlat.js")

        /// Provider should be the registered user's enterprise provider
        const ret = await zbyteDPlat.getPayer('comu', 'SampleDstoreDapp', 'storeValue', '10');
        expect(ret.provider).to.eq(await lib.getAddress('comd'));

        var balancesBefore = await readBalances([deployer,invoker,'ZbyteDPlat',worker]);

        retval = await invokeDapp.invokeViaForwarder(dapp, invoker,fnnameWrite, fnWriteparam);
        var callSuccessEvent = await lib.parseSpecificEvent(retval.txHash, dplatFwd, dplatFwdExecuteResult);
        var preExecFeeEvent = await lib.parseSpecificEvent(retval.txHash, dplat, preExecFees);
        var postExecFeeEvent = await lib.parseSpecificEvent(retval.txHash, dplat, postExecFees);

        expect(callSuccessEvent[0]).to.eq(true);
        expect(verifyResult({function:"invokeViaForwarder", dapp: await lib.getAddress(dapp)}, retval)).to.eq(true);

        var balancesAfter = await readBalances([deployer,invoker,'ZbyteDPlat',worker])

        // L1: only wrkr l1 should reduce
        // vZ: tokens reduced in comd = sum of tokens added to burn and fwdDplat
        expect(balancesBefore[invoker]['balL1']).to.eq(balancesAfter[invoker]['balL1']);
        expect(balancesBefore[invoker]['balVZ']).to.eq(balancesAfter[invoker]['balVZ']);
        expect(balancesBefore[deployer]['balL1']).to.eq(balancesAfter[deployer]['balL1']);

        // deployerZbyteOut = fwdZbyteIn+burnZbyteIn
        var deployerZbyteOut = ethers.toBigInt(ethers.parseUnits(balancesBefore[deployer]['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesAfter[deployer]['balVZ'],18))
        var fwdZbyteIn = ethers.toBigInt(ethers.parseUnits(balancesAfter['ZbyteForwarderDPlat']['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesBefore['ZbyteForwarderDPlat']['balVZ'],18))
        var burnZbyteIn = ethers.toBigInt(ethers.parseUnits(balancesAfter['burn']['balVZ'],18))
                -ethers.toBigInt(ethers.parseUnits(balancesBefore['burn']['balVZ'],18))
        console.log(deployerZbyteOut,fwdZbyteIn,burnZbyteIn);

        // check payer
        expect(ret.provider).to.eq(preExecFeeEvent[0]);
        expect(ret.provider).to.eq(postExecFeeEvent[0]);

        // check Infra fee
        expect(fwdZbyteIn).to.eq(postExecFeeEvent[1]);

        //check dplat fee
        expect(burnZbyteIn).to.eq(preExecFeeEvent[3]);

        // check payer spends
        expect(deployerZbyteOut).to.eq(postExecFeeEvent[1] + preExecFeeEvent[3]);

        expect(deployerZbyteOut).eq(fwdZbyteIn+burnZbyteIn);

        var workerL1Out = ethers.toBigInt(ethers.parseUnits(balancesBefore[worker]['balL1'],18))
            -ethers.toBigInt(ethers.parseUnits(balancesAfter[worker]['balL1'],18))
        var workerZbyteOut = (await priceFeeder.convertEthToEquivalentZbyte(workerL1Out)).value;
        expect(workerZbyteOut).lessThanOrEqual(deployerZbyteOut);
        console.log("Worker Gain%",(fwdZbyteIn - workerZbyteOut) * BigInt(100) / workerZbyteOut);

        await zbyteDPlat.deregisterDapp(deployer,'SampleDstoreDapp');
    })
    it("read value", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        retval = await invokeDapp.invokeView(dapp, fnnameVerify);    
        expect(verifyResult({function:"invokeView", dapp: await lib.getAddress(dapp),
                    result:fnVerifyParam}, retval)).to.eq(true);
    })
})


describe("Zbyte case8 test", function () {
    const dapp = 'SampleDstoreDapp'
    const deployer = 'zblp'
    const invoker = 'paag'
    const fnnameWrite = 'storeValue'
    const fnWriteparam = "14";
    const fnnameVerify = 'storedValue'
    const fnVerifyParam = "0x000000000000000000000000000000000000000000000000000000000000000e"

    const relay = "ZbyteRelay"
    const sender = 'zbyt'
    const receiver = deployer;
    const amount = "100"
    const worker = 'wrkr'
    
    before(async function () {
    })
    it("deploy Dapp", async function () {
        const deployDapp = require("../deploy/3_deploy_dapp.js");
        retval = await deployDapp(dapp, deployer);
        expect(verifyResult({function:"deployDapp",dapp: dapp}, retval)).to.eq(true);
    })
    it("init Dapp States", async function () {
        const initDapp = require("../scripts/_initStates.js");
        retval = await initDapp.initDappStates(dapp, deployer);
        expect(verifyResult({function:"initDappStates"}, retval)).to.eq(true);
    })
    it("deposit vZBYT for deployer", async function () {
        const zbyteFwdCore = require("../scripts/_zbyteForwarderCore.js")
        const dplatChain = process.env.DPLAT
        retval = await zbyteFwdCore.approveAndDeposit(relay,sender,
                receiver,amount,dplatChain,worker);
        expect(verifyResult({function:"approveAndDeposit"}, retval)).to.eq(true);
        var balances = await readBalances([deployer,invoker])
        expect(ethers.toBigInt(ethers.parseUnits(balances[receiver]['balVZ'],18)))
            .to.greaterThanOrEqual(ethers.toBigInt(ethers.parseUnits(amount,18)));
        console.log(balances)
    })

    it("set the deployer as payer", async function () {
        const zbyteDPlat = require("../scripts/_zbyteDPlat.js")
        await zbyteDPlat.registerProvider(deployer);
        await zbyteDPlat.registerEnterprise(deployer, "enterprise XYZ");
    })

    it("store value ent user open source dapp", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        const priceFeeder = require("../scripts/_zbytePriceFeeder.js");
        const zbyteDPlat = require("../scripts/_zbyteDPlat.js")

        var ret = await zbyteDPlat.getPayer(invoker, 'SampleDstoreDapp', 'storeValue', '10');
        expect(ret.provider).to.eq(await lib.getAddress(invoker));

        await zbyteDPlat.registerEnterpriseUser(deployer, invoker,"enterprise XYZ");
        ret = await zbyteDPlat.getPayer(invoker, 'SampleDstoreDapp', 'storeValue', '10');
        expect(ret.provider).to.eq(await lib.getAddress(invoker));

        await zbyteDPlat.setEnterpriseLimit(deployer,"enterprise XYZ",amount);
        ret = await zbyteDPlat.getPayer(invoker, 'SampleDstoreDapp', 'storeValue', '10');
        expect(ret.provider).to.eq(await lib.getAddress(deployer));

        ret = await zbyteDPlat.getPayer("hold", 'SampleDstoreDapp', 'storeValue', '10');
        expect(ret.provider).to.eq(await lib.getAddress("hold"));

        await zbyteDPlat.registerDapp(deployer,'SampleDstoreDapp','enterprise XYZ');
        ret = await zbyteDPlat.getPayer("comu", 'SampleDstoreDapp', 'storeValue', '10');
        expect(ret.provider).to.eq(await lib.getAddress(deployer));
        console.log("getPayer ret: ", ret);
    })
})
