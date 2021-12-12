//  const hre = require("hardhat");

async function main() {
 
  const Greeter = await hre.ethers.getContractFactory("Greeter");
  const greeter = await Greeter.deploy("Hello, Hardhat!");
  await greeter.deployed();
  console.log("Greeter deployed to:", greeter.address);

  const myVault = await hre.ethers.getContractFactory("myVault");
  const myvault = await myVault.deploy();
  await myvault.deployed();
  console.log("MyVault deployed as: ", myvault.address);
}
 
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
