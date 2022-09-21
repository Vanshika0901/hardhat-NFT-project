//SPDX-LICENSE-IDENTIFIER: MIT

pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RandomIpfsNft is VRFConsumerBaseV2, ERC721URIStorage, Ownable {
    enum Breed {
        PUG,
        SHIBA_INU,
        ST_BERNARD
    }
    //errors
    error RandomIpfsNft_RangeOutOfBound();
    error RandomIpfsNft_NeedMoreEthSent();
    error RandomIpfsNft_TransferFailed();
    //when we mint an NFT, we will trigger a chainlink VRF call to get a random number
    //using that random number, we will get a random NFT
    //Pug, Shiba Inu, St. bernard
    //Pug - super rare
    //Shiba Inu - rare
    //St. benard - common
    //users have to pay for minting
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gaseLane;
    uint32 private immutable i_callGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_dogTokenUris;
    uint256 internal immutable i_mintFee;

    //vrf helpers
    mapping(uint256 => address) s_requestIdToSender;
    uint256 public s_tokenCounter;

    //events
    event NftRequested(uint256 indexed requestId, address requester);
    event NftMinted(Breed dogBreed, address minter);

    constructor(
        address vrfCoordinator,
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callGasLimit,
        string[3] memory dogTokenUris,
        uint256 mintFee
    ) VRFConsumerBaseV2(vrfCoordinator) ERC721("Random IPFS NFT", "RIN") {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_gaseLane = gasLane;
        i_callGasLimit = callGasLimit;
        i_mintFee = mintFee;
    }

    function getChanceArray() public pure returns (uint256[3] memory) {
        return [10, 40, MAX_CHANCE_VALUE];
    }

    function requestNft() public payable returns (uint256 requestId) {
        if (msg.value < i_mintFee) {
            revert RandomIpfsNft_NeedMoreEthSent();
        }
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gaseLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callGasLimit,
            NUM_WORDS
        );
        s_requestIdToSender[requestId] = msg.sender;
        emit NftRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        address dogOwner = s_requestIdToSender[requestId];
        uint256 newTokenId = s_tokenCounter;
        _safeMint(dogOwner, newTokenId);
        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;

        Breed dogBreed = getBreedFromModdedRng(moddedRng);
        _safeMint(dogOwner, newTokenId);
        _setTokenURI(newTokenId, s_dogTokenUris[uint256(dogBreed)]);

        emit NftMinted(dogBreed, dogOwner);
    }

    function getBreedFromModdedRng(uint256 moddedRng)
        public
        pure
        returns (Breed)
    {
        uint256 cumulative = 0;
        uint256[3] memory chanceArray = getChanceArray();
        for (uint256 i = 0; i < chanceArray.length; i++) {
            if (
                (moddedRng >= cumulative) &&
                (moddedRng < cumulative + chanceArray[i])
            ) {
                return Breed(i);
            }
            cumulative += chanceArray[i];
        }
        revert RandomIpfsNft_RangeOutOfBound();
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert RandomIpfsNft_TransferFailed();
        }
    }

    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    function getDogTokenUri(uint256 index) public view returns (string memory) {
        return s_dogTokenUris[index];
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
