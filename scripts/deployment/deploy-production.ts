import { ethers } from 'hardhat';
import fs from 'fs';
import path from 'path';
import { verify } from './verify';

async function main() {
  console.log('🚀 Starting Bushido NFT production deployment...\n');
  
  // Pre-deployment checks
  const [deployer] = await ethers.getSigners();
  console.log('Deployer address:', deployer.address);
  
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log('Deployer balance:', ethers.formatEther(balance), 'ETH\n');
  
  if (balance < ethers.parseEther('0.1')) {
    throw new Error('Insufficient balance for deployment');
  }
  
  // Load whitelist data
  const whitelistData = JSON.parse(
    fs.readFileSync(path.join(__dirname, '../../whitelist/whitelist-export.json'), 'utf8')
  );
  
  console.log('Whitelist root:', whitelistData.root);
  console.log('Total whitelisted:', whitelistData.totalWhitelisted, '\n');
  
  // Deploy contract
  console.log('Deploying BushidoNFT contract...');
  const BushidoNFT = await ethers.getContractFactory('BushidoNFT');
  const bushido = await BushidoNFT.deploy();
  await bushido.waitForDeployment();
  
  const contractAddress = await bushido.getAddress();
  console.log('✅ Contract deployed to:', contractAddress);
  
  // Wait for confirmations
  console.log('\nWaiting for block confirmations...');
  await bushido.deploymentTransaction()?.wait(5);
  
  // Verify on block explorer
  console.log('\nVerifying contract on block explorer...');
  await verify(contractAddress, []);
  
  // Configure contract
  console.log('\nConfiguring contract...');
  
  // Set merkle root
  const tx1 = await bushido.setMerkleRoot(whitelistData.root);
  await tx1.wait();
  console.log('✅ Merkle root set');
  
  // Set base URI (placeholder until artwork ready)
  const tx2 = await bushido.setBaseURI('ipfs://placeholder/');
  await tx2.wait();
  console.log('✅ Base URI set');
  
  // Save deployment info
  const deploymentInfo = {
    network: network.name,
    contractAddress,
    deployer: deployer.address,
    merkleRoot: whitelistData.root,
    timestamp: new Date().toISOString(),
    blockNumber: await ethers.provider.getBlockNumber(),
  };
  
  fs.writeFileSync(
    path.join(__dirname, `../../deployments/${network.name}-deployment.json`),
    JSON.stringify(deploymentInfo, null, 2)
  );
  
  console.log('\n🎉 Deployment complete!');
  console.log('\nNext steps:');
  console.log('1. Update .env with CONTRACT_ADDRESS');
  console.log('2. Transfer ownership to multi-sig');
  console.log('3. Update frontend configuration');
  console.log('4. Set mint phase when ready to launch');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
