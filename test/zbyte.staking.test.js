const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("../scripts/lib.js");
const chai = require("chai");
const expect = chai.expect;
const fs = require('fs');
const constants = require('../scripts/constants.js')
const helpers = require("@nomicfoundation/hardhat-network-helpers");


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

describe("Staking test", function () {
    /* deployer deploys dapp, invoker invokes fnnameWrite and pays L1 */
    const dapp = 'ZbyteStaking'
    const deployer = 'zbyt'
    const rewardDuration = '100';
    const rewardAmount = '1000'
    const moveTimestep = 20;

    const depositor1 = 'comu'
    const stakeAmount = "200";
    const depositor2 = 'comd'

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
    it("set up reward token", async function () {
        let contractWithSigner = await lib.getContractWithSigner(dapp, deployer);
        let tx = await contractWithSigner.setRewardsDuration(rewardDuration);
        await expect(tx.wait())
                .to.emit(contractWithSigner,"RewardsDurationUpdated")
                .withArgs(rewardDuration);

        let rewardTokenContractWithSigner = await lib.getContractWithSigner('ZbyteDUSDT', deployer);
        let amount = ethers.parseUnits(rewardAmount,18);
        tx = await rewardTokenContractWithSigner.transfer(await lib.getAddress(dapp),amount);
        await expect(tx.wait())
                .to.emit(rewardTokenContractWithSigner,"Transfer")
                .withArgs(await lib.getAddress(deployer),
                            await lib.getAddress(dapp), amount);
        
        tx = await contractWithSigner.notifyRewardAmount(amount);
        await expect(tx.wait())
                .to.emit(contractWithSigner,"RewardAdded")
                .withArgs(amount);
        let rewardRate = await contractWithSigner.rewardRate();
        expect(rewardRate).to.equal(ethers.toBigInt(amount)/ethers.toBigInt(rewardDuration));
    })
    /*
    it("reload reward token", async function () {
        await helpers.time.increase(moveTimestep1);

        let contractWithSigner = await lib.getContractWithSigner(dapp, deployer);

        let rewardTokenContractWithSigner = await lib.getContractWithSigner('ZbyteDUSDT', deployer);
        let amount = ethers.parseUnits(rewardAmount,18);
        let tx = await rewardTokenContractWithSigner.transfer(await lib.getAddress(dapp),amount);
        await expect(tx.wait())
                .to.emit(rewardTokenContractWithSigner,"Transfer")
                .withArgs(await lib.getAddress(deployer),
                            await lib.getAddress(dapp), amount);
        
        tx = await contractWithSigner.notifyRewardAmount(amount);
        await expect(tx.wait())
                .to.emit(contractWithSigner,"RewardAdded")
                .withArgs(amount);
        let rewardRate = await contractWithSigner.rewardRate();
        let leftoverAmount = ethers.toBigInt(amount)-
                    ((ethers.toBigInt(amount)*ethers.toBigInt(moveTimestep1))/ethers.toBigInt(rewardDuration));
        let calcRewardRate = ethers.toBigInt(amount+leftoverAmount)/ethers.toBigInt(100);
        let rewRange = (ethers.toBigInt(amount)*ethers.toBigInt(5))/ethers.toBigInt(rewardDuration)
        chai.assert.closeTo(rewardRate,calcRewardRate,rewRange);
        //console.log("A",(await ethers.provider.getBlock('latest')).timestamp);
    })
    */
    it("user1 stakes 200 token", async function () {
        await helpers.time.increase(moveTimestep);
        let contractWithSigner = await lib.getContractWithSigner(dapp, depositor1);
        let rewardRate = await contractWithSigner.rewardRate();
        let rewardPerToken = await contractWithSigner.rewardPerToken();


        let amountWei = ethers.parseUnits(stakeAmount,18);
        let stakeTokenContractWithSigner = await lib.getContractWithSigner('ZbyteToken', depositor1);
        let tx = await stakeTokenContractWithSigner.approve(await lib.getAddress(dapp),amountWei);
        await expect(tx.wait())
                .to.emit(stakeTokenContractWithSigner,"Approval")
                .withArgs(await lib.getAddress(depositor1),await lib.getAddress(dapp), amountWei);

        let userRewards = await contractWithSigner.rewards(await lib.getAddress(depositor1));

        tx = await contractWithSigner.stake(amountWei);
        await expect(tx.wait())
                .to.emit(contractWithSigner,"Staked")
                .withArgs(await lib.getAddress(depositor1),amountWei);

        rewardRate = await contractWithSigner.rewardRate();
        rewardPerToken = await contractWithSigner.rewardPerToken();
        userRewards = await contractWithSigner.rewards(await lib.getAddress(depositor1));
    })
    it("user1 stakes 200 token again", async function () {
        await helpers.time.increase(moveTimestep);
        let contractWithSigner = await lib.getContractWithSigner(dapp, depositor1);
        let rewardRate = await contractWithSigner.rewardRate();
        let rewardPerToken = await contractWithSigner.rewardPerToken();


        let amountWei = ethers.parseUnits(stakeAmount,18);
        let stakeTokenContractWithSigner = await lib.getContractWithSigner('ZbyteToken', depositor1);
        let tx = await stakeTokenContractWithSigner.approve(await lib.getAddress(dapp),amountWei);
        await expect(tx.wait())
                .to.emit(stakeTokenContractWithSigner,"Approval")
                .withArgs(await lib.getAddress(depositor1),await lib.getAddress(dapp), amountWei);

        let userRewards = await contractWithSigner.rewards(await lib.getAddress(depositor1));

        tx = await contractWithSigner.stake(amountWei);
        await expect(tx.wait())
                .to.emit(contractWithSigner,"Staked")
                .withArgs(await lib.getAddress(depositor1),amountWei);

        rewardRate = await contractWithSigner.rewardRate();
        rewardPerToken = await contractWithSigner.rewardPerToken();
        userRewards = await contractWithSigner.rewards(await lib.getAddress(depositor1));
    })
    it("user1 withdraws 400 token", async function () {
        await helpers.time.increase(moveTimestep);

        let contractWithSigner = await lib.getContractWithSigner(dapp, depositor1);

        let amountWei = ethers.parseUnits('400',18);
        let tx = await contractWithSigner.withdraw(amountWei);
        await expect(tx.wait())
                .to.emit(contractWithSigner,"Withdrawn")
                .withArgs(await lib.getAddress(depositor1),amountWei);

        rewardRate = await contractWithSigner.rewardRate();
        rewardPerToken = await contractWithSigner.rewardPerToken();
        userRewards = await contractWithSigner.rewards(await lib.getAddress(depositor1));
    })
    it("user1 withdraws rewards", async function () {
        await helpers.time.increase(moveTimestep);

        let contractWithSigner = await lib.getContractWithSigner(dapp, depositor1);
        let userReward = await contractWithSigner.rewards(await lib.getAddress(depositor1));
        console.log("user reward:",userReward);
        let tx = await contractWithSigner.getReward();
        await expect(tx.wait())
                .to.emit(contractWithSigner,"RewardPaid")
                .withArgs(await lib.getAddress(depositor1),userReward);

        rewardRate = await contractWithSigner.rewardRate();
        rewardPerToken = await contractWithSigner.rewardPerToken();
        userRewards = await contractWithSigner.rewards(await lib.getAddress(depositor1));
    })
})