// scripts/deploy.ts
import { ethers } from 'hardhat';
import { verify } from './verify';

async function main() {
  console.log('Deploying Bushido NFT to Abstract...');
  
  const BushidoNFT = await ethers.getContractFactory('BushidoNFT');
  const contract = await BushidoNFT.deploy();
  await contract.waitForDeployment();
  
  const address = await contract.getAddress();
  console.log(`Contract deployed to: ${address}`);
  
  // Wait for confirmations
  await contract.deploymentTransaction()?.wait(5);
  
  // Verify on explorer
  await verify(address, []);
  
  // Set base URI
  const baseURI = `https://ipfs.io/ipfs/${process.env.METADATA_HASH}/`;
  await contract.setBaseURI(baseURI);
  
  console.log('Deployment complete!');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});