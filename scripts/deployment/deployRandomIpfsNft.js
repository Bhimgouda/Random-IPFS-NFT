const {ethers, network, run} = require("hardhat")
const {verify} = require("../../helper-functions")

const {networkConfig, developmentChains} = require("../../helper-hardhat-config")

exports.deployRandomIpfsNft = async(chainId)=>{
    const accounts = await ethers.getSigners()
    const deployer = accounts[0]

    let vrfCoordinatorAddress;
    let subscriptionId;
    const tokenUris = [
        "ipfs://QmYkUiLBLFtDiNMURryjAx7ZxKt3y2cjwyf9xzhXgiSzwa",
        "ipfs://QmUsnzuj1uG46eEeJFtr8bUh4CVxACZUwX5dGfLqLwrdV7",
        "ipfs://Qmd5C3MFeDmHEnTo3Auyy91bBPTyrGk2W8k1G1DqansdSm",
    ]

    if(developmentChains.includes(network.name)){
        const BASE_FEE = "100000000000000000"
        const GAS_PRICE_LINK = "1000000000" // 0.000000001 LINK per gas
    
            console.log("Deploying Mocks.........")
            const vrfCoordinatorV2MockFactory = await ethers.getContractFactory("VRFCoordinatorV2Mock")
            const vrfCoordinatorV2Mock = await vrfCoordinatorV2MockFactory.deploy(BASE_FEE, GAS_PRICE_LINK)
            
            vrfCoordinatorAddress = vrfCoordinatorV2Mock.address
            
            // Getting subscription Id
            const tx = await vrfCoordinatorV2Mock.createSubscription()
            const txReceipt = await tx.wait(1)
            subscriptionId = txReceipt.events[0].args.subId
            
    } else{
        vrfCoordinatorAddress = networkConfig[chainId].vrfCoordinatorV2
        subscriptionId = networkConfig[chainId].subscriptionId
    }

    console.log("-------------------------------")

    const args = [
        vrfCoordinatorAddress,
        subscriptionId,
        networkConfig[chainId].gasLane,
        networkConfig[chainId].callbackGasLimit,
        tokenUris,
        networkConfig[chainId].mintFee
    ]

    const randomIpfsNftFactory = await ethers.getContractFactory("RandomIpfsNft");
    const randomIpfsNft = await randomIpfsNftFactory.deploy(
        vrfCoordinatorAddress,
        subscriptionId,
        networkConfig[chainId].gasLane,
        networkConfig[chainId].callbackGasLimit,
        tokenUris,
        networkConfig[chainId].mintFee
    )
    await randomIpfsNft.deployTransaction.wait(network.config.blockConfirmations)

    // Verify the deployment
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        console.log("Verifying...")
        await verify(randomIpfsNft.address, args)
    }
}