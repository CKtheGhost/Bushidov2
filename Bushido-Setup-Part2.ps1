# Bushido-Setup-Part2.ps1
# Part 2: Smart Contract Package Setup

param(
    [string]$ProjectPath = (Get-Location).Path
)

#region Helper Functions
function Write-Status {
    param(
        [string]$Message,
        [string]$Type = 'Info'
    )
    
    $colors = @{
        'Info' = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error' = 'Red'
    }
    
    $symbols = @{
        'Info' = '►'
        'Success' = '✓'
        'Warning' = '⚠'
        'Error' = '✗'
    }
    
    Write-Host "$($symbols[$Type]) " -NoNewline -ForegroundColor $colors[$Type]
    Write-Host $Message
}

function Write-FileContent {
    param(
        [string]$Path,
        [string]$Content
    )
    
    $directory = Split-Path $Path -Parent
    if ($directory -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    Set-Content -Path $Path -Value $Content -Encoding UTF8
}
#endregion

#region Contract Files
function Create-ContractsPackage {
    Write-Status "Setting up contracts package..." "Info"
    
    Push-Location "contracts"
    try {
        # Package.json for contracts
        $package = @{
            name = "@bushido/contracts"
            version = "1.0.0"
            private = $true
            scripts = @{
                "compile" = "hardhat compile"
                "test" = "hardhat test"
                "deploy" = "hardhat run scripts/deploy.ts"
                "verify" = "hardhat verify"
                "coverage" = "hardhat coverage"
            }
            devDependencies = @{
                "hardhat" = "^2.19.4"
                "@nomicfoundation/hardhat-toolbox" = "^4.0.0"
                "@openzeppelin/contracts" = "^5.0.1"
                "dotenv" = "^16.3.1"
            }
        }
        
        $package | ConvertTo-Json -Depth 10 | Set-Content "package.json" -Encoding UTF8
        
        # Hardhat config
        $hardhatConfig = @'
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    abstractTestnet: {
      url: process.env.ABSTRACT_TESTNET_RPC || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
    abstract: {
      url: process.env.ABSTRACT_RPC || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || ""
  }
};
'@
        
        Write-FileContent "hardhat.config.js" $hardhatConfig
        
        # Main NFT contract
        $nftContract = @'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IBushidoNFT.sol";
import "./libraries/VotingPower.sol";

contract BushidoNFT is ERC721Enumerable, Ownable, IBushidoNFT {
    using Counters for Counters.Counter;
    using VotingPower for uint256;
    
    // Constants
    uint256 public constant MAX_SUPPLY = 1600;
    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public constant MINT_PRICE = 0.08 ether;
    uint256 public constant CLANS_COUNT = 8;
    
    // State
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => uint256) public tokenClan;
    mapping(uint256 => uint256) public tokenRarity;
    mapping(address => uint256) public mintedPerWallet;
    
    bool public mintActive;
    string private _baseTokenURI;
    
    // Events
    event MintActivated(uint256 timestamp);
    event TokenMinted(address indexed to, uint256 tokenId, uint256 clan, uint256 rarity);
    event VoteCast(uint256 indexed episodeId, uint256 indexed tokenId, string choice);
    
    constructor() ERC721("Bushido", "BUSHIDO") Ownable(msg.sender) {}
    
    function activateMint() external onlyOwner {
        require(!mintActive, "Already active");
        mintActive = true;
        emit MintActivated(block.timestamp);
    }
    
    function mint(uint256 quantity) external payable {
        require(mintActive, "Mint not active");
        require(quantity > 0 && quantity <= MAX_PER_WALLET, "Invalid quantity");
        require(mintedPerWallet[msg.sender] + quantity <= MAX_PER_WALLET, "Exceeds limit");
        require(_tokenIdCounter.current() + quantity <= MAX_SUPPLY, "Exceeds supply");
        require(msg.value >= MINT_PRICE * quantity, "Insufficient ETH");
        
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            
            // Determine clan and rarity
            uint256 clan = (tokenId - 1) / 200;
            uint256 rarity = _determineRarity(tokenId);
            
            tokenClan[tokenId] = clan;
            tokenRarity[tokenId] = rarity;
            
            _safeMint(msg.sender, tokenId);
            emit TokenMinted(msg.sender, tokenId, clan, rarity);
        }
        
        mintedPerWallet[msg.sender] += quantity;
    }
    
    function getVotingPower(uint256 tokenId) public view returns (uint256) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return tokenRarity[tokenId].calculateVotingPower();
    }
    
    function _determineRarity(uint256 tokenId) private pure returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(tokenId))) % 1000;
        
        if (rand < 25) return 4; // Legendary - 2.5%
        if (rand < 100) return 3; // Epic - 7.5%
        if (rand < 250) return 2; // Rare - 15%
        if (rand < 500) return 1; // Uncommon - 25%
        return 0; // Common - 50%
    }
    
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
'@
        
        Write-FileContent "contracts/BushidoNFT.sol" $nftContract
        
        # Interface
        $interface = @'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBushidoNFT {
    function getVotingPower(uint256 tokenId) external view returns (uint256);
    function tokenClan(uint256 tokenId) external view returns (uint256);
    function tokenRarity(uint256 tokenId) external view returns (uint256);
}
'@
        
        Write-FileContent "interfaces/IBushidoNFT.sol" $interface
        
        # Voting Power Library
        $votingLibrary = @'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library VotingPower {
    function calculateVotingPower(uint256 rarity) internal pure returns (uint256) {
        if (rarity == 0) return 1;   // Common
        if (rarity == 1) return 4;   // Uncommon
        if (rarity == 2) return 9;   // Rare
        if (rarity == 3) return 16;  // Epic
        if (rarity == 4) return 25;  // Legendary
        return 1;
    }
}
'@
        
        Write-FileContent "libraries/VotingPower.sol" $votingLibrary
        
        Write-Status "Contract files created" "Success"
        
    } finally {
        Pop-Location
    }
}

function Create-DeploymentScript {
    Write-Status "Creating deployment script..." "Info"
    
    $deployScript = @'
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
'@
    
    Write-FileContent "contracts/scripts/deploy.ts" $deployScript
    Write-Status "Deployment script created" "Success"
}
#endregion

#region Main Execution
try {
    Write-Host "`n🏯 Bushido NFT Setup - Part 2" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════`n" -ForegroundColor DarkRed
    
    # Ensure we're in project directory
    if ($ProjectPath -ne (Get-Location).Path) {
        Set-Location $ProjectPath
    }
    
    # Create contracts package
    Create-ContractsPackage
    Create-DeploymentScript
    
    # Create deployments directory
    New-Item -ItemType Directory -Path "contracts/deployments" -Force | Out-Null
    
    Write-Host "`n✨ Part 2 Complete!" -ForegroundColor Green
    Write-Host "Run Part 3 to set up frontend and backend`n" -ForegroundColor Yellow
    
} catch {
    Write-Status "Setup failed: $_" "Error"
    exit 1
}
#endregion