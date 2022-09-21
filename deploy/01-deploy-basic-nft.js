const { network, ethers } = require("hardhat");
const { deploymentChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log("-------------------------------");

  const args = [];
  const basicNft = await deploy("BasicNft", {
    from: deployer,
    log: true,
    args: args,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  if (
    !deploymentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    console.log("Verifying");
    await verify(basicNft.address, args);
  }
};
