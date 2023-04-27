const {network, run} = require("hardhat");

const { deployRandomIpfsNft } = require("./deployRandomIpfsNft");

async function main(){
    await run("compile")
    const chainId = network.config.chainId;
    await deployRandomIpfsNft(chainId)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})