const hre = require("hardhat");
const ethers = hre.ethers;
const lib = require("./lib.js");
const chai = require("chai");
const expect = chai.expect;

const contractName = "ZbyteForwarderDPlat";

async function setZbyteDPlat(owner) {
    try {
      let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
      let dplatAddress = await lib.getAddress("ZbyteDPlat");
  
      console.log("setZbyteDPlat: " + dplatAddress);

      const tx = await contractWithSigner.setZbyteDPlat(dplatAddress);
      await expect(tx.wait())
      .to.emit(contractWithSigner,"ForwarderDplatSet")
      .withArgs(dplatAddress);
  
      return { function: "setZbyteDPlat",
               ZbyteDPlat: dplatAddress
             }
  
    } catch (error) {
        console.log(error);
        throw(error);
    }
  }

  async function setMinProcessingGas(owner, minGas) {
    try {
      let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
  
      console.log("setMinProcessingGas: ", minGas);
      const tx = await contractWithSigner.setMinProcessingGas(minGas);
      await expect(tx.wait())
      .to.emit(contractWithSigner,"ForwarderDplatMinimumProcessingGasSet")
      .withArgs(minGas);
  
      return { function: "setMinProcessingGas",
               MinimumProcessingGase: minGas
             }
  
    } catch (error) {
        console.log(error);
        throw(error);
    }
  }
  
  async function registerWorker(owner, worker) {
    try {
      let contractWithSigner = await lib.getContractWithSigner(contractName, owner);
      var workerAddress = [];
      var registerWorkerAddress = [];
      for(var i = 0; i < worker.length; i++) {
        workerAddress[i] = await lib.getAddress(worker[i]);
        registerWorkerAddress[i] = true;
      }
      console.log("registerWorker: " + workerAddress + " " + registerWorkerAddress);
      const tx = await contractWithSigner.registerWorkers(workerAddress, registerWorkerAddress);

      for(var i = 0; i < worker.length; i++) {
          await expect(tx.wait())
          .to.emit(contractWithSigner,"ForwarderDplatWorkerRegistered")
          .withArgs(workerAddress[i], registerWorkerAddress[i]);
      }
  
      return { function:"registerWorker",
               WorkerAddress:workerAddress,
               RegisterWorkerAddress:registerWorkerAddress
             }
  
    } catch (error) {
        console.log(error);
        throw(error);
    }
  }
  
  async function setPostExecGas(owner, postExecGas) {
    try {
      let contractWithSigner = await lib.getContractWithSigner(contractName, owner);

      console.log("setPostExecGas: ", postExecGas);
      const tx = await contractWithSigner.setPostExecGas(postExecGas);
      await expect(tx.wait())
      .to.emit(contractWithSigner,"ForwarderDplatPostExecGasSet")
      .withArgs(postExecGas);

      return { function: "setPostExecGas",
               PostExecGas: postExecGas
             }

    } catch (error) {
        console.log(error);
        throw(error);
    }
  }

  module.exports = {
    "registerWorker":registerWorker,
    "setZbyteDPlat":setZbyteDPlat,
    "setMinProcessingGas":setMinProcessingGas,
    "setPostExecGas":setPostExecGas
  }