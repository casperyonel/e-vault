require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan"); // Installed npm too

require('dotenv').config()

const etherscanCredentials = ""

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  networks: {
    // hardhat: {
    //   url: "http://127.0.0.1:8545/",
    //   accounts: [`0x${process.env.PRIVATE_KEY}`]
    // },
    localhost: {
      chainId: 31337
    },
    kovan: {
      url: "https://kovan.infura.io/v3/c765fea966964da58dacb7a38ddf910c",
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    },
  }
  // etherscan: {
  //   apiKey: etherscanCredentials
}