var argv = require('minimist')(process.argv.slice(2));
var cp = require('child_process')

function _execute(cmd) {
    try {
        console.log("Running:"+cmd)
        let res = cp.execSync(cmd)
        console.log(res.toString())
        return res
    }
    catch (err){ 
        console.log("output", err)
        console.log("sdterr",err.stderr.toString())
    }
}

function _set_envs(chains) {
    core = chains[0]
    dplat = chains[1]
    let set_cmd = "export CORE="+core+ " && ";
    set_cmd +=  "export DPLAT="+dplat+ " && ";
    if (core.startsWith('hh')) {
        set_cmd += "export CORECFG="+core+".config.js && "
        set_cmd += "export DPLATCFG="+dplat+".config.js && "
    } else {
        set_cmd += "export CORECFG=hardhat.config.js && "
        set_cmd += "export DPLATCFG=hardhat.config.js && "
    }
    return set_cmd;
}

function dictToCmd(dict) {
    cmd = "npx hardhat "+dict['task']
    var keys = Object.keys(dict);
    const skip_keys = ['task','_','core','dplat','runon']
    for(let i = 0; i<keys.length; i++) {
        if (!(skip_keys.includes(keys[i]))) {
            console.log(keys[i]+" "+dict[keys[i]])
            cmd += " --"+keys[i]+" "+dict[keys[i]]+" "
        }
    }
    if(dict['runon'] =='core') {
        cmd += " --network $CORE --config $CORE.config.js"
    } else if(dict['runon'] =='dplat') {
        cmd += " --network $DPLAT --config $DPLAT.config.js"
    }
    return cmd;
}

function execCmd(dict) {
    cmd = dictToCmd(dict);
    set_cmd = _set_envs([dict['core'],dict['dplat']]);
    _execute(set_cmd + " " + cmd);
}

if (require.main === module) {
    console.log(argv)
    execCmd(argv)
}

module.exports = {
    execCmd:execCmd
}