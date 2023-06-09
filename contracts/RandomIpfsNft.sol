// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

error RandomIpfsNft__RangeOutOfBounds();
error RandomIpfsNft__NeedMoreEthSent();
error RandomIpfsNft__NotAnOwner();
error RandomIpfsNft__TransferFailed();

contract RandomIpfsNft is VRFConsumerBaseV2, ERC721{

    // Collectible Declarations
    enum Collectible {
        NYAN_CAT,
        CRYPTO_QUEEN,
        BORED_APE
    }

    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;


    // VRF helpers
    mapping(uint256 => address) public s_requestIdToSender;

    // NFT variables
    uint256 public s_tokenCounter;
    string[] internal s_tokenUris;
    mapping (uint256 => uint256) public s_tokenIdToCollectible;
    uint256 internal i_mintFee;
    address i_owner; 

    // Events 
    event NftRequested(uint256 indexed requestId, address requester);
    event NftMinted(Collectible Collectible, address minter);
 
    constructor(address vrfCoordinatorV2, uint64 subscriptionId, bytes32 gasLane, uint32 callbackGasLimit, string[3] memory tokenUris, uint256 mintFee) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721("RandomIPFSNFT", "RIN") {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        s_tokenUris = tokenUris;
        i_mintFee = mintFee;
        i_owner = msg.sender;
    }

    modifier onlyOwner {
        if(msg.sender !=  i_owner) revert RandomIpfsNft__NotAnOwner();
        _;
    }

    function requestNft() public payable returns(uint256 requestId) {
        if(msg.value < i_mintFee) revert RandomIpfsNft__NeedMoreEthSent();

        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        s_requestIdToSender[requestId] = msg.sender;

        emit NftRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override{
        address collectibleOwner = s_requestIdToSender[requestId];
        uint256 newTokenId = s_tokenCounter;

        // Getting the random value
        uint256 randValue = randomWords[0] % 100;
        s_tokenCounter++ ;
        _safeMint(collectibleOwner, newTokenId);

        Collectible collectible = getCollectibleFromRandValue(randValue);

        // Collectiblecasting collectible enum to get its index
        s_tokenIdToCollectible[newTokenId] = uint256(collectible);

        emit NftMinted(collectible, collectibleOwner);
    }

    function getCollectibleFromRandValue(uint256 randValue) public pure returns (Collectible) {
        if(!(randValue >= 0 && randValue < 100)) revert RandomIpfsNft__RangeOutOfBounds();
        if(randValue <= 10){
            return Collectible(0);
        }
        else if(randValue <= 40){
            return Collectible(1);
        }
        return Collectible(2);
    }

    function tokenURI(uint256 tokenId) public override view returns(string memory){
        uint256 collectible = s_tokenIdToCollectible[tokenId];
        return s_tokenUris[collectible];
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if(!success) revert RandomIpfsNft__TransferFailed();
    }

    function getMintFee() public view returns(uint256){
        return i_mintFee;
    }

    function getTokenUris(uint256 index) public view returns (string memory) {
        return s_tokenUris[index];
    }

    function getTokenCounter() public view returns(uint256){
        return s_tokenCounter;
    }
}