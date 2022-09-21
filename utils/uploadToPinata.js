const pinataSdk = require("@pinata/sdk");
const path = require("path");
const fs = require("fs");
require("dotenv").config();

const pinataApiKey = process.env.PINATA_API_KEY;
const pinataSecretKey = process.env.PINATA_SECRET_KEY;
const pinata = pinataSdk(pinataApiKey, pinataSecretKey);

async function storeImages(imagesFilePath) {
  const fullFilePath = path.resolve(imagesFilePath);
  const files = fs.readdirSync(fullFilePath);
  let responses = [];
  for (fileIndex in files) {
    const readableStreamForFile = fs.createReadStream(
      `${fullFilePath}/${files[fileIndex]}`
    );
    try {
      const response = await pinata.pinFileToIPFS(readableStreamForFile);
      responses.push(response);
    } catch (error) {
      console.log(error);
    }
  }
  return { responses, files };
}

module.exports = { storeImages };
