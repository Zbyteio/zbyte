require("hardhat/config");
const fs = require("fs");
const { task } = require("hardhat/config");
/*
npx hardhat node --fork https://rpc-mumbai.maticvigil.com/ --port 4545 --config hhmumbai.config.js
npx hardhat node --fork https://avalanche-fuji.infura.io/v3/c4adc113c65d419fa4aa11d536d51e2c --port 3545 --config hhfuji.config.js
*/
/*
export CORE=hhmumbai
export CCONFIG=hhmumbai.config.js
#cd deployments/$CORE && shopt -s extglob && rm -rf -v !(ZbyteToken.json|ZbyteTokenForwarder.json) && cd -
npx hardhat zDeploy --api core --owner zbyt --network $CORE --config $CCONFIG
npx hardhat zDeploy --api initCoreStates --owner zbyt --network $CORE --config $CCONFIG
export DPLAT=hhmumbai
export DCONFIG=hhmumbai.config.js
npx hardhat zDeploy --api dplat --owner zbyt --network $DPLAT --config $DCONFIG
npx hardhat zDeploy --api dapp --owner comd --network $DPLAT --config $DCONFIG
npx hardhat zDeploy --api initDplatStates --owner zbyt --network $DPLAT --config $DCONFIG
npx hardhat zDeploy --api initCoreStateForDplat --owner zbyt --relay ZbyteRelay --network $CORE --config $CCONFIG
npx hardhat zDeploy --api initDappStates --owner zbyt --network $DPLAT --config $DCONFIG
export DPLAT=fuji
export DCONFIG=hardhat.config.js
npx hardhat zDeploy --api dplat --owner zbyt --network $DPLAT --config $DCONFIG
npx hardhat zDeploy --api dapp --owner comd --network $DPLAT --config $DCONFIG
npx hardhat zDeploy --api initDplatStates --owner zbyt --network $DPLAT --config $DCONFIG
npx hardhat zDeploy --api initCoreStateForDplat --owner zbyt --relay ZbyteRelay --network $CORE --config $CCONFIG
npx hardhat zDeploy --api initDappStates --owner zbyt --network $DPLAT --config $DCONFIG
*/
task("zDeploy", "Deploy contracts")
.addParam("api", "API to call")
.addOptionalParam("owner", "owner of the contract to be called")
.addOptionalParam("relay","Relay name")
.setAction(
    async (taskArgs, hre) => {
        let retval;
        if(taskArgs.api == "core") {
            const deployCore = require("../deploy/1_deploy_core.js");
            retval = await deployCore(taskArgs.owner);
        } else if(taskArgs.api == "dplat") {
            const deployDplat = require("../deploy/2_deploy_dplat.js");
            retval = await deployDplat(taskArgs.owner);
        } else if(taskArgs.api == "dapp") {
            const deployDapp = require("../deploy/3_deploy_dapp.js");
            retval = await deployDapp(taskArgs.owner);
        } else if(taskArgs.api == "initCoreStates") {
            const init = require("../scripts/_initStates.js");
            retval = await init.initCoreStates(taskArgs.owner);
        } else if(taskArgs.api == "initDplatStates") {
            const init = require("../scripts/_initStates.js");
            retval = await init.initDplatStates(taskArgs.owner);
        } else if(taskArgs.api == "initDappStates") {
            const init = require("../scripts/_initStates.js");
            retval = await init.initDappStates();
        } else if(taskArgs.api == "initCoreStateForDplat") {
            const init = require("../scripts/_initStates.js");
            const dplatChain = process.env.DPLAT
            retval = await init.initCoreStateForDplat(taskArgs.owner,dplatChain,taskArgs.relay);
        }
        //require("../scripts/lib.js").logResult(retval)
    });

/*
npx hardhat zbyteToken --api balanceOf --account zbyt   --network $CORE  --config $CCONFIG
npx hardhat zbyteToken --api transfer --receiver comp --amount 100 --sender zbyt  --network $CORE  --config $CCONFIG
npx hardhat zbyteToken --api transfer --receiver comd --amount 100 --sender zbyt  --network $CORE  --config $CCONFIG
npx hardhat zbyteToken --api approve --approver comd --approvee ZbyteEscrow --amount 100 --network $CORE --config $CCONFIG
cat test/.result.json 
*/
task("zbyteToken", "Zbyte Token Tasks")
.addParam("api", "API to call")
.addOptionalParam("owner","Owner of the contract")
.addOptionalParam("account","account address for balanceOf")
.addOptionalParam("sender","token sender address")
.addOptionalParam("receiver","token receiver address")
.addOptionalParam("approver","token approver address")
.addOptionalParam("approvee","token approvee address")
.addOptionalParam("amount","amount of tokens")
.setAction(
    async (taskArgs, hre) => {
        const zbyteToken = require("../scripts/_zbyteToken.js")
        let retval;
        if(taskArgs.api == "transfer") {
            retval = await zbyteToken.transfer(taskArgs.sender,taskArgs.receiver,taskArgs.amount);
        } else if(taskArgs.api == "approve") {
            retval = await zbyteToken.approve(taskArgs.approver,taskArgs.approvee,taskArgs.amount);
        } else if(taskArgs.api == "transferFrom") {
            retval = await zbyteToken.transferFrom(taskArgs.approvee,taskArgs.sender,taskArgs.receiver,taskArgs.amount);
        } else if(taskArgs.api == "balanceOf") {
            retval = await zbyteToken.balanceOf(taskArgs.account);
        }
        require("../scripts/lib.js").logResult(retval)
    });

/*
npx hardhat zbyteEscrow --api deposit --relay ZbyteRelay --receiver comd --amount 100 --sender comd  --network $CORE --config $CCONFIG
*/
task("zbyteEscrow", "Zbyte Escrow Tasks")
.addParam("api", "API to call")
.addOptionalParam("relay","Relay name")
.addOptionalParam("paymaster","vToken paymaster")
.addOptionalParam("receiver","vToken receiver")
.addOptionalParam("amount","amount of tokens to deposit")
.addOptionalParam("sender","token depositor")
.addOptionalParam("owner","owner of the contrat")
.addOptionalParam("cost","cost of the operation")
.setAction(
    async (taskArgs, hre) => {
        const zbyteEscrow = require("../scripts/_zbyteEscrow.js")
        const lib = require("../scripts/lib.js")
        let retval;
        if(taskArgs.api == "deposit") {
            const dplatChain = process.env.DPLAT
            retval = await zbyteEscrow.deposit(taskArgs.relay,dplatChain,
                    taskArgs.receiver,taskArgs.cost,taskArgs.amount,taskArgs.sender);
        } else if(taskArgs.api == "withdraw") {
            const dplatChain = process.env.DPLAT
            retval = await zbyteEscrow.withdraw(taskArgs.relay,dplatChain,
                    taskArgs.paymaster,taskArgs.receiver,taskArgs.owner);
        }
        require("../scripts/lib.js").logResult(retval);
    });

/*
npx hardhat zbyteRelay --api receiveCall --srcch mumbai --srcrelay 0x0Da4829132509bB68641A6C044bD1a2d33A2Ae87 --dstch fuji --dstrelay 0xAdc52C012D2b5D046C32C4534Cd5fF965699fe55 --payload 0x000000000000000000000000000000000000000000000000000000000000a8690000000000000000000000004f0bc1236e5d0bf112c3382bf63706d08b912b7da5ac53be661047ad87b6ee11c2aa7cb647e5b04d16ebae684b56bb1893103982000000000000000000000000c75d934bbbbc87e4b1939dadcda5ce6c6925b8b300000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000004440c10f190000000000000000000000008f4bfde402d934da748b80e5db6e1b2535873f730000000000000000000000000000000000000000000000056bc75e2d6310000000000000000000000000000000000000000000000000000000000000 --amount 100 --owner zbyt --network $DPLAT --config $DCONFIG
*/
task("zbyteRelay", "Zbyte Relay Tasks")
.addParam("api", "API to call")
.addOptionalParam("owner","Owner of the contract")
.addOptionalParam("srcch","Source chain")
.addOptionalParam("srcrelay","Destination chain relay")
.addOptionalParam("dstch","Destination chain")
.addOptionalParam("dstrelay","Destination chain relay")
.addOptionalParam("payload","Payload for call")
.addOptionalParam("amount","amount of tokens to deposit")
.setAction(
    async (taskArgs, hre) => {
        const zbyteRelay = require("../scripts/_zbyteRelay.js")
        let retval;
        if(taskArgs.api == "receiveCall") {
            retval = await zbyteRelay.receiveCall(taskArgs.srcch,taskArgs.srcrelay,
                    taskArgs.dstch,taskArgs.dstrelay,taskArgs.payload,
                    taskArgs.amount,taskArgs.owner);
        }

        require("../scripts/lib.js").logResult(retval);
    });

/*
npx hardhat zbyteToken --api transfer --receiver comd --amount 100 --sender zbyt  --network $CORE  --config $CCONFIG
npx hardhat zbyteForwarderCore --api approveAndDeposit --relay ZbyteRelay --receiver comd --amount 100 --sender comd --worker wrkr --network $CORE --config $CCONFIG
*/
task("zbyteForwarderCore", "Zbyte Core Forwarder Tasks")
.addParam("api", "API to call")
.addOptionalParam("relay","Relay name")
.addOptionalParam("sender","token depositor")
.addOptionalParam("receiver","vToken receiver")
.addOptionalParam("worker","worker address")
.addOptionalParam("amount","amount of tokens to deposit")
.setAction(
    async (taskArgs, hre) => {
        const zbyteFwdCore = require("../scripts/_zbyteForwarderCore.js")
        const lib = require("../scripts/lib.js")
        let retval;
        if(taskArgs.api == "approveAndDeposit") {
            const dplatChain = process.env.DPLAT
            retval = await zbyteFwdCore.approveAndDeposit(taskArgs.relay,taskArgs.sender,
                    taskArgs.receiver,taskArgs.amount,dplatChain,taskArgs.worker);
        } 
    });

/*
npx hardhat zbyteVToken --api balanceOf --account comd   --network $DPLAT  --config $DCONFIG
cat test/.result.json 
*/
task("zbyteVToken", "vZbyte Token Tasks")
.addParam("api", "API to call")
.addOptionalParam("account","account address for balanceOf")
.addOptionalParam("approver","token approver address")
.addOptionalParam("approvee","token approvee address")
.addOptionalParam("amount","amount of tokens")
.addOptionalParam("owner","zbyte token holder")
.addOptionalParam("receiver","vzbyte receiver")
.addOptionalParam("relay","relay to be used")
.addOptionalParam("dplatchain","chain on which vzbyte will be minted")
.setAction(
    async (taskArgs, hre) => {
        const zbyteToken = require("../scripts/_zbyteVToken.js")
        let retval;
        if(taskArgs.api == "balanceOf") {
            retval = await zbyteToken.balanceOf(taskArgs.account);
        } else if(taskArgs.api == "approve") {
            retval = await zbyteToken.approve(taskArgs.approver,taskArgs.approvee,taskArgs.amount);
        } else if(taskArgs.api == "mintVZbyteGasless") {
            retval = await zbyteToken.mintVZbyteGasless(taskArgs.owner,taskArgs.receiver, taskArgs.amount, taskArgs.relay, taskArgs.dplatchain);
        }
        require("../scripts/lib.js").logResult(retval)
    });

/*
npx hardhat zbyteDPlat --api registerEnterprise --provideragent paag --enterprise "XYZ.com"   --network $DPLAT  --config $DCONFIG
npx hardhat zbyteDPlat --api registerEnterpriseUser --enterpriseuser entd  --provideragent paag --enterprise "XYZ.com"   --network $DPLAT  --config $DCONFIG
cat test/.result.json 
*/
task("zbyteDPlat", "ZbyteDPlat Tasks")
.addParam("api", "API to call")
.addOptionalParam("enterprise","enterprise")
.addOptionalParam("enterpriseuser","enterprise user")
.addOptionalParam("enterprisedapp","enterprise dapp")
.addOptionalParam("provideragent","provider agent")
.addOptionalParam("limit","enterprise limit")
.setAction(
    async (taskArgs, hre) => {
        const zbyteDPlat = require("../scripts/_zbyteDPlat.js")
        let retval;
        if(taskArgs.api == "registerEnterprise") {
            retval = await zbyteDPlat.registerEnterprise(taskArgs.provideragent, taskArgs.enterprise);
        } else if(taskArgs.api == "registerEnterpriseUser") {
            retval = await zbyteDPlat.registerEnterpriseUser(taskArgs.provideragent, taskArgs.enterpriseuser, taskArgs.enterprise);
        } else if(taskArgs.api == "registerDapp") {
            retval = await zbyteDPlat.registerDapp(taskArgs.provideragent, taskArgs.enterprisedapp, taskArgs.enterprise);
        } else if(taskArgs.api == "setEnterpriseLimit") {
            retval = await zbyteDPlat.setEnterpriseLimit(taskArgs.provideragent, taskArgs.enterprise, taskArgs.limit);
        }
        require("../scripts/lib.js").logResult(retval)
    });

/*
npx hardhat DStore --api dstore --value 10 --user "entd" --network $DPLAT  --config $DCONFIG
npx hardhat DStore --api dstoregl --value 20 --user "entd" --network $DPLAT  --config $DCONFIG 
cat test/.result.json 
*/
task("DStore", "SampleDstoreDapp Tasks")
.addParam("api", "API to call")
.addParam("value", "Value to be set")
.addParam("user", "Account signing the transaction")
.addOptionalParam("submitter","Account which submits the transaction to the forwarder")
.setAction(
    async (taskArgs, hre) => {
        const dStore = require("../scripts/_sampleDstoreDapp.js")
        let retval;
        if(taskArgs.api == "dstore") {
            retval = await dStore.storeValue(taskArgs.user, taskArgs.value);
        } else if(taskArgs.api == "dstoregl") {
            retval = await dStore.storeValueViaFwd(taskArgs.submitter, taskArgs.user, taskArgs.value);
        }
        require("../scripts/lib.js").logResult(retval)
    });
