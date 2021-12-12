const hre = require('hardhat');
const fs = require('fs');


async function main() {

  const MyVault = await hre.ethers.getContractFactory("myVault");
  const myVault = await MyVault.deploy();
    // Passing in the constructor since we need an argument.  
  await myVault.deployed();
  console.log("Vault deployed to: ", myVault.address);





  // const contractName = 'myVault';
  // await hre.run("compile");
  // const smartContract = await hre.ethers.getContractFactory(contractName);
  // const myVault = await smartContract.deploy();
  // await myVault.deployed();
  // console.log(`${contractName} deployed to: ${myVault.address}`);
}

 
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
