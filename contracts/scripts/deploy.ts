const hre = require("hardhat");

async function main() {
  console.log("Deploying BushidoNFT...");
  
  const BushidoNFT = await hre.ethers.getContractFactory("BushidoNFT");
  const bushido = await BushidoNFT.deploy();
  
  await bushido.waitForDeployment();
  
  const address = await bushido.getAddress();
  console.log("BushidoNFT deployed to:", address);
  
  // Save deployment info
  const fs = require("fs");
  const deploymentInfo = {
    network: hre.network.name,
    contract: "BushidoNFT",
    address: address,
    timestamp: new Date().toISOString()
  };
  
  fs.writeFileSync(
    `deployments/${hre.network.name}.json`,
    JSON.stringify(deploymentInfo, null, 2)
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
