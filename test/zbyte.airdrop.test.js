const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("../scripts/lib.js");
const chai = require("chai");
const expect = chai.expect;
const fs = require('fs');
const constants = require('../scripts/constants.js')

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

/*
describe("Zbyte airdrop test", function () {
    const dapp = 'ZbyteAirdropNFT'
    const deployer = 'zbyt'
    const distributor = 'prov'
    const user1 = 'comd'
    const user2 = 'entd'
    const ERC20 = 'ZbyteDUSDT'
    const startTokenId = 1;
    let dusdtPerToken = ethers.parseUnits('1',18); // change for mainnet

    before(async function () {
    })
    it("deploy airdrop Dapp", async function () {
        const deployDapp = require("../deploy/3_deploy_dapp.js");
        retval = await deployDapp(dapp, deployer);
        expect(verifyResult({function:"deployDapp",dapp: dapp}, retval)).to.eq(true);
    })
    it("init Dapp States", async function () {
        const initDapp = require("../scripts/_initStates.js");
        retval = await initDapp.initDappStates(dapp, deployer);
        expect(verifyResult({function:"initDappStates"}, retval)).to.eq(true);
    })
    it("mint and transfer to distributor for airdrop1", async function () {
        const airdrop = require("../scripts/_zbyteAirdropDapp.js");

        var balancesBefore = await readBalances([deployer,distributor])
        retval = await airdrop.mintForAirdrop('10','coinstoreAirdrop',startTokenId,deployer,{gasLimit:10e18});
        expect(verifyResult({function:"mintForAirdrop"}, retval)).to.eq(true);

        var balancesAfter = await readBalances([deployer,distributor])
        expect(ethers.toBigInt(ethers.parseUnits(balancesBefore[deployer]['balL1'],18)))
            .to.greaterThan(ethers.toBigInt(ethers.parseUnits(balancesAfter[deployer]['balL1'],18)));
    })
    it("distributor transfers to user", async function () {
        const airdrop = require("../scripts/_zbyteAirdropDapp.js");
        retval = await airdrop.safeTransferFrom(startTokenId,user1,distributor);
        expect(verifyResult({function:"safeTransferFrom"}, retval)).to.eq(true);

        retval = await airdrop.safeTransferFrom(startTokenId+1,user2,distributor);
        expect(verifyResult({function:"safeTransferFrom"}, retval)).to.eq(true);
        retval = await airdrop.safeTransferFrom(startTokenId+2,user2,distributor);
        expect(verifyResult({function:"safeTransferFrom"}, retval)).to.eq(true);
        retval = await airdrop.safeTransferFrom(startTokenId+3,user2,distributor);
        expect(verifyResult({function:"safeTransferFrom"}, retval)).to.eq(true);
    })
    it("owner transfers ERC20 to contract", async function () {
        const abi = [
            "function transfer(address to, uint amount) returns (bool)",
            "event Transfer(address indexed from, address indexed to, uint amount)"
        ];
        let erc20Address = await lib.getAddress('ZbyteDUSDT');
        let airdropNFTAddress = await lib.getAddress('ZbyteAirdropNFT');
        var amountWei = ethers.parseUnits('20',18);
        let contract = new ethers.Contract(erc20Address, abi, ethers.provider);
        let privateKey = lib.getPrvKey(deployer);
        let deployerAddress = await lib.getAddress(deployer);
        let wallet = new ethers.Wallet(privateKey, ethers.provider);
        let contractWithSigner = contract.connect(wallet);
        let tx = await contractWithSigner.transfer(airdropNFTAddress,amountWei);
        await expect(tx.wait())
                .to.emit(contractWithSigner,"Transfer")
                .withArgs(deployerAddress,airdropNFTAddress,amountWei);
    })
    it("user1 redeems", async function () {
        const airdrop = require("../scripts/_zbyteAirdropDapp.js");
        const abi = [
            "function balanceOf(address owner) view returns (uint256)",
        ];
        let erc20Address = await lib.getAddress('ZbyteDUSDT');
        let contract = new ethers.Contract(erc20Address, abi, ethers.provider);
        let user1Address = await lib.getAddress(user1);
        let balanceBefore = await contract.balanceOf(user1Address);

        let retval = await airdrop.ownerOf(startTokenId);
        expect(verifyResult({function:"ownerOf"}, retval)).to.eq(true);

        retval = await airdrop.redeem(user1,user1);    
        expect(verifyResult({function:"Redeemed"}, retval)).to.eq(true);

        let ownerAfter = await airdrop.ownerOf(startTokenId);
        expect(verifyResult({function:"ownerOf"}, retval)).to.eq(false);

        let balanceAfter = await contract.balanceOf(user1Address);
        expect(ethers.toBigInt(balanceAfter) - ethers.toBigInt(balanceBefore))
            .to.eq(ethers.toBigInt(dusdtPerToken));
    })
    it("remove all funds", async function () {
        const airdrop = require("../scripts/_zbyteAirdropDapp.js");
        const abi = [
            "function balanceOf(address owner) view returns (uint256)",
        ];
        let erc20Address = await lib.getAddress('ZbyteDUSDT');
        let contract = new ethers.Contract(erc20Address, abi, ethers.provider);
        let deployerAddress = await lib.getAddress(deployer);
        let balanceBefore = await contract.balanceOf(deployerAddress);
        retval = await airdrop.transferRemainingERC20(deployer,deployer);
        expect(verifyResult({function:"transferRemainingERC20"}, retval)).to.eq(true);
        let balanceAfter = await contract.balanceOf(deployerAddress);
        expect(ethers.toBigInt(balanceAfter)).to.greaterThan(ethers.toBigInt(balanceBefore));
    })
})
*/

describe("Zbyte airdrop test (call only via fwd)", function () {

    const dapp = 'ZbyteAirdropNFT'
    const deployer = 'zbyt'
    const distributor = 'prov'
    const user1 = 'comd'
    const user2 = 'entd'
    const ERC20 = 'ZbyteDUSDT'
    const startTokenId = 1;
    let dusdtPerToken = ethers.parseUnits('1',18); // change for mainnet
    let worker = 'wrkr'

    before(async function () {
    })
    it("deploy airdrop Dapp", async function () {
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
    it("deposit vZBYT for deployer", async function () {
        const zbyteFwdCore = require("../scripts/_zbyteForwarderCore.js")
        const dplatChain = process.env.DPLAT
        const relay = "ZbyteRelay"
        const sender = 'zbyt'
        const receiver = deployer;
        const amount = "100"
        const worker = "wrkr"
        retval = await zbyteFwdCore.approveAndDeposit(relay,sender,
                receiver,amount,dplatChain,worker);
        expect(verifyResult({function:"approveAndDeposit"}, retval)).to.eq(true);
        var balances = await readBalances([deployer])
        expect(ethers.toBigInt(ethers.parseUnits(balances[deployer]['balVZ'],18)))
            .to.greaterThanOrEqual(ethers.toBigInt(ethers.parseUnits(amount,18)));
        retval = await zbyteFwdCore.approveAndDeposit(relay,sender,
                distributor,amount,dplatChain,worker);
        expect(verifyResult({function:"approveAndDeposit"}, retval)).to.eq(true);
        var balances = await readBalances([distributor])
        expect(ethers.toBigInt(ethers.parseUnits(balances[distributor]['balVZ'],18)))
            .to.greaterThanOrEqual(ethers.toBigInt(ethers.parseUnits(amount,18)));
        retval = await zbyteFwdCore.approveAndDeposit(relay,sender,
                user1,amount,dplatChain,worker);
        expect(verifyResult({function:"approveAndDeposit"}, retval)).to.eq(true);
        var balances = await readBalances([user1])
        expect(ethers.toBigInt(ethers.parseUnits(balances[user1]['balVZ'],18)))
            .to.greaterThanOrEqual(ethers.toBigInt(ethers.parseUnits(amount,18)));
    })
    it("mint and transfer to distributor for airdrop1", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        var balancesBefore = await readBalances([deployer,user1,user2])

        retval = await invokeDapp.invokeViaForwarder(dapp, deployer, 'mintForAirdrop',
            '10,coinstoreAirdrop');
        expect(verifyResult({function:"invokeViaForwarder", dapp: await lib.getAddress(dapp)}, retval)).to.eq(true);

        var balancesAfter = await readBalances([deployer,user1,user2])

        expect(ethers.toBigInt(ethers.parseUnits(balancesBefore[deployer]['balL1'],18)))
            .to.eq(ethers.toBigInt(ethers.parseUnits(balancesAfter[deployer]['balL1'],18)));
        expect(ethers.toBigInt(ethers.parseUnits(balancesBefore[worker]['balL1'],18)))
            .to.greaterThan(ethers.toBigInt(ethers.parseUnits(balancesAfter[worker]['balL1'],18)));
        expect(ethers.toBigInt(ethers.parseUnits(balancesBefore[deployer]['balVZ'],18)))
            .to.greaterThan(ethers.toBigInt(ethers.parseUnits(balancesAfter[deployer]['balVZ'],18)));
        })
    it("distributor transfers to user", async function () {
        const invokeDapp = require("../scripts/_dapp.js")
        var balancesBefore = await readBalances([deployer,distributor,user1,user2])
        var distributorAddress = await lib.getAddress(distributor);
        var user1Address = await lib.getAddress(user1);
        retval = await invokeDapp.invokeViaForwarder(dapp, distributor, 
            'safeTransferFrom(address,address,uint256)',
        distributorAddress+","+user1Address+","+startTokenId.toString());
        expect(verifyResult({function:"invokeViaForwarder", dapp: await lib.getAddress(dapp)}, retval)).to.eq(true);

        var balancesAfter = await readBalances([deployer,distributor,user1,user2])
        expect(ethers.toBigInt(ethers.parseUnits(balancesBefore[worker]['balL1'],18)))
            .to.greaterThan(ethers.toBigInt(ethers.parseUnits(balancesAfter[worker]['balL1'],18)));
        expect(ethers.toBigInt(ethers.parseUnits(balancesBefore[distributor]['balVZ'],18)))
            .to.greaterThan(ethers.toBigInt(ethers.parseUnits(balancesAfter[distributor]['balVZ'],18)));
    })
    it("owner transfers ERC20 to contract", async function () {
        const abi = [
            "function transfer(address to, uint amount) returns (bool)",
            "event Transfer(address indexed from, address indexed to, uint amount)"
        ];
        let erc20Address = await lib.getAddress('ZbyteDUSDT');
        let airdropNFTAddress = await lib.getAddress('ZbyteAirdropNFT');
        var amountWei = ethers.parseUnits('20',18);
        let contract = new ethers.Contract(erc20Address, abi, ethers.provider);
        let privateKey = lib.getPrvKey(deployer);
        let deployerAddress = await lib.getAddress(deployer);
        let wallet = new ethers.Wallet(privateKey, ethers.provider);
        let contractWithSigner = contract.connect(wallet);
        let tx = await contractWithSigner.transfer(airdropNFTAddress,amountWei);
        await expect(tx.wait())
                .to.emit(contractWithSigner,"Transfer")
                .withArgs(deployerAddress,airdropNFTAddress,amountWei);
    })
    it("user1 redeems", async function () {
        const airdrop = require("../scripts/_zbyteAirdropDapp.js");
        const abi = [
            "function balanceOf(address owner) view returns (uint256)",
        ];
        let erc20Address = await lib.getAddress('ZbyteDUSDT');
        let contract = new ethers.Contract(erc20Address, abi, ethers.provider);
        let user1Address = await lib.getAddress(user1);
        let balanceBefore = await contract.balanceOf(user1Address);

        let retval = await airdrop.ownerOf(startTokenId);
        expect(verifyResult({function:"ownerOf"}, retval)).to.eq(true);

        const invokeDapp = require("../scripts/_dapp.js")
        var balancesBefore = await readBalances([deployer,distributor,user1,user2])
        retval = await invokeDapp.invokeViaForwarder(dapp, user1, 
            'redeem',user1Address);
        expect(verifyResult({function:"invokeViaForwarder", dapp: await lib.getAddress(dapp)}, retval)).to.eq(true);
        var balancesAfter = await readBalances([deployer,distributor,user1,user2])

        expect(ethers.toBigInt(ethers.parseUnits(balancesBefore[worker]['balL1'],18)))
            .to.greaterThan(ethers.toBigInt(ethers.parseUnits(balancesAfter[worker]['balL1'],18)));
        expect(ethers.toBigInt(ethers.parseUnits(balancesBefore[user1]['balVZ'],18)))
            .to.greaterThan(ethers.toBigInt(ethers.parseUnits(balancesAfter[user1]['balVZ'],18)));

        let ownerAfter = await airdrop.ownerOf(startTokenId);
        expect(verifyResult({function:"ownerOf"}, retval)).to.eq(false);

        let balanceAfter = await contract.balanceOf(user1Address);
        expect(ethers.toBigInt(balanceAfter) - ethers.toBigInt(balanceBefore))
            .to.eq(ethers.toBigInt(dusdtPerToken));
    })
    it("remove all funds", async function () {
        const airdrop = require("../scripts/_zbyteAirdropDapp.js");
        const abi = [
            "function balanceOf(address owner) view returns (uint256)",
        ];
        let erc20Address = await lib.getAddress('ZbyteDUSDT');
        let contract = new ethers.Contract(erc20Address, abi, ethers.provider);
        let deployerAddress = await lib.getAddress(deployer);
        let balanceBefore = await contract.balanceOf(deployerAddress);
        retval = await airdrop.transferRemainingERC20(deployer,deployer);
        expect(verifyResult({function:"transferRemainingERC20"}, retval)).to.eq(true);
        let balanceAfter = await contract.balanceOf(deployerAddress);
        expect(ethers.toBigInt(balanceAfter)).to.greaterThan(ethers.toBigInt(balanceBefore));
    })
})
