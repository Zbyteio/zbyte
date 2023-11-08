const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("../scripts/lib.js");
const chai = require("chai");
const expect = chai.expect;

const zbyteToken = require('../scripts/_zbyteToken.js');
const fwdCore = require('../scripts/_fwdExecCore.js')

describe("Zbyte Token Tests", function () {
    before(async function () {
    })
  
    it("should mint 100 ZBYT to comd", async function () {
      await zbyteToken.mint('zbyt','comd','100');
    })
    it("should transfer 50 ZBYT from comd to comp", async function () {
        await zbyteToken.transfer('comd','comp','50');
    })
    it("should transfer 50 ZBYT from comd to comp, by hold", async function () {
        await zbyteToken.approve('comd','hold','50')
        await zbyteToken.transferFrom('hold','comd','comp','50');
    })
    it("mint should fail when paused", async function () {
        await zbyteToken.pause('zbyt')
        let contractWithSigner = await lib.getContractWithSigner("ZbyteToken", "zbyt");
        var amountWei = ethers.parseUnits("100",18);
        var userAddress = await lib.getAddress("comd");
        await expect(contractWithSigner.mint(userAddress,amountWei)).to.be.revertedWith("Pausable: paused")
    })
    it("mint should succeed when unpaused", async function () {
        await zbyteToken.unpause('zbyt')
        await zbyteToken.mint('zbyt','comd','100');
    })
    it("Should not mint more than limit", async function () {
        await zbyteToken.mint('zbyt','comd','5000000000');
        await zbyteToken.mint('zbyt','comd','999999800');
        let contractWithSigner = await lib.getContractWithSigner("ZbyteToken", "zbyt");
        var amountWei = ethers.parseUnits("1",18);
        var userAddress = await lib.getAddress("comd");
        await expect(contractWithSigner.mint(userAddress,amountWei)).to.be.revertedWith("ERC20Capped: cap exceeded")
    })
    it("Transfer 1000 from comd to comp using forwarder", async function () {
        let amount = "1000"
        let fromAddress = await lib.getAddress("comd")
        let toAddress = await lib.getAddress("comp")
        ret = await fwdCore.executeViaForwarder("ZbyteToken",
            "comd","transfer",[toAddress,ethers.parseUnits(amount,18)])
        let amountWei = ethers.parseUnits(amount,18)
        const tokenC = await lib.getContract("ZbyteToken")

        const contractWithSigner = await lib.getContractWithSigner("ZbyteForwarderCore","comp");
        await expect(contractWithSigner.execute(ret.req,ret.sign))
        .to.emit(tokenC,"Transfer")
        .withArgs(fromAddress,toAddress,amountWei);
    })
})



