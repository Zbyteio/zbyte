const prvKeysList = [
    process.env.ZBYT_PRIVATE_KEY,
    process.env.HOLD_PRIVATE_KEY,
    process.env.BURN_PRIVATE_KEY,
    process.env.COMP_PRIVATE_KEY,
    process.env.COMW_PRIVATE_KEY,
    process.env.PROV_PRIVATE_KEY,
    process.env.ZBLW_PRIVATE_KEY,
    process.env.COMU_PRIVATE_KEY,
    process.env.COMD_PRIVATE_KEY,
    process.env.ENTD_PRIVATE_KEY,
    process.env.ENTP_PRIVATE_KEY,
    process.env.ZBLP_PRIVATE_KEY,
    process.env.PAAG_PRIVATE_KEY,
    process.env.WRKR_PRIVATE_KEY
]

const namedAccountToIndex = {
    zbyt:0,
    hold:1,
    burn:2,
    comp:3,
    comw:4,
    prov:5,
    zblw:6,
    comu:7,
    comd:8,
    entd:9,
    entp:10,
    zblp:11,
    paag:12,
    wrkr:13
}
    
const privateKeys = {
    zbyt: process.env.ZBYT_PRIVATE_KEY,
    hold: process.env.HOLD_PRIVATE_KEY,
    burn: process.env.BURN_PRIVATE_KEY,
    comp: process.env.COMP_PRIVATE_KEY,
    comw: process.env.COMW_PRIVATE_KEY,
    prov: process.env.PROV_PRIVATE_KEY,
    zblw: process.env.ZBLW_PRIVATE_KEY,
    comu: process.env.COMU_PRIVATE_KEY,
    comd: process.env.COMD_PRIVATE_KEY,
    entd: process.env.ENTD_PRIVATE_KEY,
    entp: process.env.ENTP_PRIVATE_KEY,
    zblp: process.env.ZBLP_PRIVATE_KEY,
    paag: process.env.PAAG_PRIVATE_KEY,
    wrkr: process.env.WRKR_PRIVATE_KEY
}
const relayNameToId = {
    'ZbyteRelay': 0,
    'Axelar':1
}
const logFile = "./test/.result.json"
const latestFile = "./test/.latest.json"
const logAckFile = "./test/.resultAck.json"
const core = 'hhmumbai'

module.exports = {
    prvKeysList:prvKeysList,
    privateKeys:privateKeys,
    namedAccountToIndex:namedAccountToIndex,
    relayNameToId:relayNameToId,
    logFile:logFile,
    latestFile:latestFile,
    logAckFile:logAckFile,
    core:core
}
