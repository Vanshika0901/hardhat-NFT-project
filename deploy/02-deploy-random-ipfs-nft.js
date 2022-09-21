const { network, ethers } = require("hardhat");
const { deploymentChains, networkConfig } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");
const { storeImages } = require("../utils/uploadToPinata");

const imageLocation = "./images/random";

const metadataTemplate = {
  name: "",
  description: "",
  image: "",
  attributes: [
    {
      trait_type: "Cuteness",
      value: 100,
    },
  ],
};

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;
  let tokenUris;
  //get the ipfs hashes for our images
  if (process.env.UPLOAD_TO_PINATA == "true") {
    tokenUris = await handleTokenUris();
  }

  let vrfCoordinatorAddress, subscriptionId;

  if (deploymentChains.includes(network.name)) {
    const vrfCoordinatorMock = await ethers.getContract("VRFCoordinatorV2Mock");
    vrfCoordinatorAddress = vrfCoordinatorMock.address;
    const tx = await vrfCoordinatorMock.createSubscription();
    const txReciept = await tx.wait(1);
    subscriptionId = txReciept.events[0].args.subId;
  } else {
    vrfCoordinatorAddress = networkConfig[chainId].vrfCoordinatorV2;
    subscriptionId = networkConfig[chainId].subscriptionId;
  }

  console.log("-------------------------------------");
  await storeImages(imageLocation);

  const args = [
    // //vrfCoordinatorAddress,
    // //subscriptionId,
    // networkConfig[chainId].gasLane,
    // networkConfig[chainId].callbackGasLimit,
    // networkConfig[chainId].mintFee,
  ];

  async function handleTokenUris() {
    tokenUris = [];
    //set the images in ipfs
    //set the metadata in ipfs

    return tokenUris;
  }
};
module.exports.tags = ["all", "randomipfs", "main"];
