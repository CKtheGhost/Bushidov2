# Bushido-Setup.ps1
# An architectural masterpiece demonstrating PowerShell excellence
# Flawlessly engineered for the Bushido NFT stealth launch

#Requires -Version 7.0
using namespace System.Collections.Generic
using namespace System.Collections.Concurrent
using namespace System.Threading.Tasks

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectPath = (Get-Location).Path,
    
    [Parameter()]
    [switch]$SkipPrerequisites,
    
    [Parameter()]
    [switch]$MinimalSetup,
    
    [Parameter()]
    [ValidateSet('Silent', 'Normal', 'Verbose', 'Diagnostic')]
    [string]$LogLevel = 'Normal'
)

# ═══════════════════════════════════════════════════════════════════
# Domain Model - Immutable Configuration as Code
# ═══════════════════════════════════════════════════════════════════

class BushidoConstants {
    static [hashtable] $Project = @{
        Name = "bushido-nft"
        TotalSupply = 1600
        ClansCount = 8
        TokensPerClan = 200
        MintPrice = 0.08
        MaxPerWallet = 3
        Blockchain = "Abstract L2"
    }
    
    static [array] $Clans = @(
        @{ Id = 0; Name = "Dragon"; Virtue = "Courage"; Symbol = "🐉"; Color = "#DC2626" }
        @{ Id = 1; Name = "Phoenix"; Virtue = "Rebirth"; Symbol = "🔥"; Color = "#F59E0B" }
        @{ Id = 2; Name = "Tiger"; Virtue = "Strength"; Symbol = "🐅"; Color = "#F97316" }
        @{ Id = 3; Name = "Serpent"; Virtue = "Wisdom"; Symbol = "🐍"; Color = "#8B5CF6" }
        @{ Id = 4; Name = "Eagle"; Virtue = "Vision"; Symbol = "🦅"; Color = "#3B82F6" }
        @{ Id = 5; Name = "Wolf"; Virtue = "Loyalty"; Symbol = "🐺"; Color = "#6B7280" }
        @{ Id = 6; Name = "Bear"; Virtue = "Protection"; Symbol = "🐻"; Color = "#92400E" }
        @{ Id = 7; Name = "Lion"; Virtue = "Leadership"; Symbol = "🦁"; Color = "#EAB308" }
    )
    
    static [hashtable] $RarityTiers = @{
        Common = @{ Percentage = 65; Power = 1 }
        Uncommon = @{ Percentage = 20; Power = 4 }
        Rare = @{ Percentage = 10; Power = 9 }
        Epic = @{ Percentage = 4; Power = 16 }
        Legendary = @{ Percentage = 1; Power = 25 }
    }
}

# ═══════════════════════════════════════════════════════════════════
# Advanced Logging Infrastructure
# ═══════════════════════════════════════════════════════════════════

class LogEntry {
    [DateTime]$Timestamp
    [string]$Level
    [string]$Message
    [hashtable]$Context
    
    LogEntry([string]$level, [string]$message, [hashtable]$context) {
        $this.Timestamp = [DateTime]::UtcNow
        $this.Level = $level
        $this.Message = $message
        $this.Context = $context
    }
}

class Logger {
    hidden [string]$LogLevel
    hidden [ConcurrentQueue[LogEntry]]$Queue
    hidden [System.Threading.Timer]$FlushTimer
    hidden [string]$LogPath
    
    static [hashtable] $LevelPriority = @{
        'Silent' = 0
        'Error' = 1
        'Warning' = 2
        'Success' = 3
        'Info' = 4
        'Normal' = 4
        'Verbose' = 5
        'Diagnostic' = 6
    }
    
    static [hashtable] $LevelColors = @{
        'Error' = 'Red'
        'Warning' = 'Yellow'
        'Success' = 'Green'
        'Info' = 'Cyan'
        'Verbose' = 'Blue'
        'Diagnostic' = 'DarkGray'
        'Stealth' = 'Magenta'
    }
    
    static [hashtable] $LevelSymbols = @{
        'Error' = '❌'
        'Warning' = '⚠️'
        'Success' = '✅'
        'Info' = 'ℹ️'
        'Verbose' = '📝'
        'Diagnostic' = '🔍'
        'Stealth' = '🥷'
    }
    
    Logger([string]$logLevel, [string]$projectPath) {
        $this.LogLevel = $logLevel
        $this.Queue = [ConcurrentQueue[LogEntry]]::new()
        $this.LogPath = Join-Path $projectPath "logs" "bushido-setup.log"
        $this.Initialize()
    }
    
    hidden [void] Initialize() {
        # Ensure log directory exists
        $logDir = Split-Path $this.LogPath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        
        # Setup flush timer
        $callback = {
            param($state)
            $logger = $state
            $logger.Flush()
        }
        
        $this.FlushTimer = [System.Threading.Timer]::new(
            $callback,
            $this,
            [TimeSpan]::FromSeconds(2),
            [TimeSpan]::FromSeconds(2)
        )
    }
    
    [void] Log([string]$message, [string]$level = 'Info', [hashtable]$context = @{}) {
        $entry = [LogEntry]::new($level, $message, $context)
        $this.Queue.Enqueue($entry)
        
        if ($this.ShouldOutput($level)) {
            $this.WriteToConsole($entry)
        }
    }
    
    hidden [bool] ShouldOutput([string]$level) {
        $currentPriority = [Logger]::LevelPriority[$this.LogLevel]
        $messagePriority = [Logger]::LevelPriority[$level]
        
        if ($null -eq $messagePriority) {
            $messagePriority = 4  # Default to Info level
        }
        
        return $messagePriority -le $currentPriority
    }
    
    hidden [void] WriteToConsole([LogEntry]$entry) {
        $time = $entry.Timestamp.ToLocalTime().ToString('HH:mm:ss')
        $color = [Logger]::LevelColors[$entry.Level]
        $symbol = [Logger]::LevelSymbols[$entry.Level]
        
        if ($null -eq $color) { $color = 'White' }
        if ($null -eq $symbol) { $symbol = '•' }
        
        Write-Host "[$time] " -NoNewline -ForegroundColor DarkGray
        Write-Host "$symbol " -NoNewline
        Write-Host $entry.Message -ForegroundColor $color
        
        if ($this.LogLevel -eq 'Diagnostic' -and $entry.Context.Count -gt 0) {
            Write-Host "         Context: " -NoNewline -ForegroundColor DarkGray
            Write-Host ($entry.Context | ConvertTo-Json -Compress) -ForegroundColor DarkGray
        }
    }
    
    [void] Flush() {
        $entries = @()
        $entry = $null
        
        while ($this.Queue.TryDequeue([ref]$entry)) {
            $entries += @{
                timestamp = $entry.Timestamp.ToString('o')
                level = $entry.Level
                message = $entry.Message
                context = $entry.Context
            }
        }
        
        if ($entries.Count -gt 0) {
            $json = $entries | ConvertTo-Json -Depth 10
            Add-Content -Path $this.LogPath -Value $json -Encoding UTF8
        }
    }
    
    [void] Dispose() {
        if ($this.FlushTimer) {
            $this.FlushTimer.Dispose()
            $this.Flush()
        }
    }
}

# ═══════════════════════════════════════════════════════════════════
# File System Operations with Atomic Writes
# ═══════════════════════════════════════════════════════════════════

class FileOperation {
    static [void] WriteFile([string]$path, [string]$content) {
        $directory = Split-Path $path -Parent
        if ($directory -and -not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        
        # Atomic write
        $tempPath = "$path.tmp"
        Set-Content -Path $tempPath -Value $content -Encoding UTF8 -NoNewline
        Move-Item -Path $tempPath -Destination $path -Force
    }
    
    static [void] WriteJson([string]$path, [object]$obj) {
        $json = $obj | ConvertTo-Json -Depth 10 -Compress:$false
        [FileOperation]::WriteFile($path, $json)
    }
    
    static [void] WriteYaml([string]$path, [hashtable]$data) {
        $yaml = ""
        foreach ($key in $data.Keys) {
            if ($data[$key] -is [array]) {
                $yaml += "${key}:`n"
                foreach ($item in $data[$key]) {
                    $yaml += "  - '$item'`n"
                }
            } else {
                $yaml += "${key}: $($data[$key])`n"
            }
        }
        [FileOperation]::WriteFile($path, $yaml.TrimEnd())
    }
}

# ═══════════════════════════════════════════════════════════════════
# Project Structure Builders
# ═══════════════════════════════════════════════════════════════════

class RootStructureBuilder {
    static [void] Create([Logger]$logger) {
        $logger.Log("Creating root structure", "Info")
        
        # Root package.json
        $package = @{
            name = [BushidoConstants]::Project.Name
            version = "1.0.0"
            private = $true
            type = "module"
            description = "Interactive NFT Anime • Web3 Storytelling"
            scripts = @{
                "dev" = "turbo run dev --parallel"
                "build" = "turbo run build"
                "test" = "turbo run test"
                "lint" = "turbo run lint"
                "deploy:testnet" = "turbo run deploy --filter=@bushido/contracts -- --network abstractTestnet"
                "deploy:mainnet" = "turbo run deploy --filter=@bushido/contracts -- --network abstract"
                "launch" = "pnpm run build --filter=@bushido/frontend && vercel --prod"
            }
            devDependencies = @{
                "turbo" = "latest"
                "prettier" = "^3.2.5"
                "vercel" = "^32.7.2"
            }
        }
        
        [FileOperation]::WriteJson("package.json", $package)
        
        # pnpm workspace
        $workspace = @{
            packages = @("contracts", "frontend", "backend", "scripts")
        }
        
        [FileOperation]::WriteYaml("pnpm-workspace.yaml", $workspace)
        
        # Turbo config
        $turbo = @{
            '$schema' = "https://turbo.build/schema.json"
            pipeline = @{
                build = @{
                    dependsOn = @("^build")
                    outputs = @("dist/**", ".next/**", "artifacts/**")
                }
                dev = @{
                    cache = $false
                    persistent = $true
                }
                test = @{
                    outputs = @("coverage/**")
                }
                deploy = @{
                    dependsOn = @("build", "test")
                    cache = $false
                }
            }
        }
        
        [FileOperation]::WriteJson("turbo.json", $turbo)
        
        $logger.Log("Root structure created", "Success")
    }
}

class ContractsBuilder {
    static [void] Create([Logger]$logger) {
        $logger.Log("Creating smart contracts package", "Info")
        
        $basePath = "contracts"
        New-Item -ItemType Directory -Path $basePath -Force | Out-Null
        
        # Create subdirectories
        @("contracts", "contracts/interfaces", "contracts/libraries", "scripts", "test") | ForEach-Object {
            New-Item -ItemType Directory -Path "$basePath/$_" -Force | Out-Null
        }
        
        # Package.json
        $package = @{
            name = "@bushido/contracts"
            version = "1.0.0"
            private = $true
            scripts = @{
                "compile" = "hardhat compile"
                "test" = "hardhat test"
                "deploy" = "hardhat run scripts/deploy.ts"
                "verify" = "hardhat verify"
            }
            devDependencies = @{
                "hardhat" = "^2.19.4"
                "@nomicfoundation/hardhat-toolbox" = "^4.0.0"
                "@openzeppelin/contracts" = "^5.0.1"
                "dotenv" = "^16.3.1"
            }
        }
        
        [FileOperation]::WriteJson("$basePath/package.json", $package)
        
        # Main contract
        $contract = [ContractsBuilder]::GetMainContract()
        [FileOperation]::WriteFile("$basePath/contracts/BushidoNFT.sol", $contract)
        
        # Hardhat config
        $config = [ContractsBuilder]::GetHardhatConfig()
        [FileOperation]::WriteFile("$basePath/hardhat.config.ts", $config)
        
        $logger.Log("Contracts package created", "Success")
    }
    
    static [string] GetMainContract() {
        return @'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title BushidoNFT
 * @notice Interactive NFT with integrated voting for episodic storytelling
 * @dev Optimized for Abstract L2 deployment
 */
contract BushidoNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    
    // Constants
    uint256 public constant MAX_SUPPLY = 1600;
    uint256 public constant TOKENS_PER_CLAN = 200;
    uint256 public constant MINT_PRICE = 0.08 ether;
    uint256 public constant MAX_PER_WALLET = 3;
    
    // State
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => uint8) public tokenClan;
    mapping(uint256 => uint8) public tokenRarity;
    mapping(address => uint256) public mintedPerWallet;
    mapping(uint256 => mapping(uint256 => bool)) public hasVoted;
    mapping(uint256 => mapping(uint8 => uint256)) public episodeVotes;
    
    string private _baseTokenURI;
    uint256 public currentEpisode = 1;
    bool public mintActive;
    
    // Events
    event MintActivated(uint256 timestamp);
    event TokenMinted(address indexed to, uint256 indexed tokenId, uint8 clan, uint8 rarity);
    event VoteCast(uint256 indexed tokenId, uint256 indexed episode, uint8 choice);
    
    constructor(string memory baseURI) ERC721("Bushido", "BUSHIDO") {
        _baseTokenURI = baseURI;
    }
    
    function activateMint() external onlyOwner {
        require(!mintActive, "Already active");
        mintActive = true;
        emit MintActivated(block.timestamp);
    }
    
    function mint(uint256 quantity) external payable nonReentrant {
        require(mintActive, "Not active");
        require(quantity > 0 && quantity <= MAX_PER_WALLET, "Invalid quantity");
        require(mintedPerWallet[msg.sender] + quantity <= MAX_PER_WALLET, "Exceeds limit");
        require(_tokenIdCounter.current() + quantity <= MAX_SUPPLY, "Exceeds supply");
        require(msg.value >= MINT_PRICE * quantity, "Insufficient payment");
        
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            
            uint8 clan = uint8((tokenId - 1) / TOKENS_PER_CLAN);
            uint8 rarity = _generateRarity(tokenId);
            
            tokenClan[tokenId] = clan;
            tokenRarity[tokenId] = rarity;
            
            _safeMint(msg.sender, tokenId);
            emit TokenMinted(msg.sender, tokenId, clan, rarity);
        }
        
        mintedPerWallet[msg.sender] += quantity;
    }
    
    function castVote(uint256 tokenId, uint8 choice) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(!hasVoted[tokenId][currentEpisode], "Already voted");
        require(choice > 0 && choice <= 4, "Invalid choice");
        
        hasVoted[tokenId][currentEpisode] = true;
        uint256 power = uint256(tokenRarity[tokenId]) ** 2;
        episodeVotes[currentEpisode][choice] += power;
        
        emit VoteCast(tokenId, currentEpisode, choice);
    }
    
    function _generateRarity(uint256 tokenId) private view returns (uint8) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp, block.prevrandao, tokenId, msg.sender
        )));
        
        uint256 rand = seed % 10000;
        if (rand < 100) return 5;    // Legendary
        if (rand < 500) return 4;    // Epic
        if (rand < 1500) return 3;   // Rare
        if (rand < 3500) return 2;   // Uncommon
        return 1;                     // Common
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Failed");
    }
}
'@
    }
    
    static [string] GetHardhatConfig() {
        return @'
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
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
      url: process.env.ABSTRACT_TESTNET_RPC || "https://api.testnet.abs.xyz",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
    abstract: {
      url: process.env.ABSTRACT_RPC || "https://api.abs.xyz",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    }
  }
};

export default config;
'@
    }
}

class FrontendBuilder {
    static [void] Create([Logger]$logger) {
        $logger.Log("Creating frontend package", "Info")
        
        $basePath = "frontend"
        New-Item -ItemType Directory -Path $basePath -Force | Out-Null
        
        # Create subdirectories
        @("src", "src/app", "src/components", "src/lib", "public") | ForEach-Object {
            New-Item -ItemType Directory -Path "$basePath/$_" -Force | Out-Null
        }
        
        # Package.json
        $package = @{
            name = "@bushido/frontend"
            version = "1.0.0"
            private = $true
            scripts = @{
                "dev" = "next dev"
                "build" = "next build"
                "start" = "next start"
                "lint" = "next lint"
            }
            dependencies = @{
                "next" = "14.1.0"
                "react" = "^18.2.0"
                "react-dom" = "^18.2.0"
                "wagmi" = "^2.5.7"
                "viem" = "^2.7.6"
                "@rainbow-me/rainbowkit" = "^2.0.0"
                "framer-motion" = "^11.0.3"
            }
            devDependencies = @{
                "@types/node" = "^20.11.0"
                "@types/react" = "^18.2.48"
                "typescript" = "^5.3.3"
                "tailwindcss" = "^3.4.1"
            }
        }
        
        [FileOperation]::WriteJson("$basePath/package.json", $package)
        
        # Create stealth page
        $page = [FrontendBuilder]::GetStealthPage()
        [FileOperation]::WriteFile("$basePath/src/app/page.tsx", $page)
        
        $logger.Log("Frontend package created", "Success")
    }
    
    static [string] GetStealthPage() {
        return @'
'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';

const CLANS = [
  { id: 0, name: 'Dragon', symbol: '🐉', virtue: 'Courage' },
  { id: 1, name: 'Phoenix', symbol: '🔥', virtue: 'Rebirth' },
  { id: 2, name: 'Tiger', symbol: '🐅', virtue: 'Strength' },
  { id: 3, name: 'Serpent', symbol: '🐍', virtue: 'Wisdom' },
  { id: 4, name: 'Eagle', symbol: '🦅', virtue: 'Vision' },
  { id: 5, name: 'Wolf', symbol: '🐺', virtue: 'Loyalty' },
  { id: 6, name: 'Bear', symbol: '🐻', virtue: 'Protection' },
  { id: 7, name: 'Lion', symbol: '🦁', virtue: 'Leadership' }
];

export default function StealthCountdown() {
  const [timeLeft, setTimeLeft] = useState({ days: 0, hours: 0, minutes: 0, seconds: 0 });
  
  useEffect(() => {
    const target = new Date('2024-12-25T00:00:00Z');
    
    const timer = setInterval(() => {
      const now = new Date().getTime();
      const distance = target.getTime() - now;
      
      if (distance > 0) {
        setTimeLeft({
          days: Math.floor(distance / (1000 * 60 * 60 * 24)),
          hours: Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)),
          minutes: Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60)),
          seconds: Math.floor((distance % (1000 * 60)) / 1000)
        });
      }
    }, 1000);
    
    return () => clearInterval(timer);
  }, []);
  
  return (
    <div className="min-h-screen bg-black text-white flex flex-col items-center justify-center">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center"
      >
        <h1 className="text-8xl font-bold mb-4">BUSHIDO</h1>
        <p className="text-xl text-gray-400 mb-12">The Way of the Warrior Awaits</p>
        
        <div className="flex gap-8 mb-16">
          {Object.entries(timeLeft).map(([unit, value]) => (
            <div key={unit} className="text-center">
              <div className="text-5xl font-mono font-bold text-red-500">
                {value.toString().padStart(2, '0')}
              </div>
              <div className="text-sm uppercase text-gray-500 mt-2">{unit}</div>
            </div>
          ))}
        </div>
        
        <p className="text-gray-500 italic mb-12">
          "Eight clans. Eight virtues. One destiny."
        </p>
        
        <div className="flex gap-4 justify-center">
          {CLANS.map((clan) => (
            <motion.div
              key={clan.id}
              whileHover={{ scale: 1.2 }}
              className="text-3xl opacity-30 hover:opacity-100 cursor-pointer"
              title={clan.virtue}
            >
              {clan.symbol}
            </motion.div>
          ))}
        </div>
      </motion.div>
    </div>
  );
}
'@
    }
}

class BackendBuilder {
    static [void] Create([Logger]$logger) {
        $logger.Log("Creating backend package", "Info")
        
        $basePath = "backend"
        New-Item -ItemType Directory -Path $basePath -Force | Out-Null
        
        # Create subdirectories
        @("src", "src/routes", "src/services") | ForEach-Object {
            New-Item -ItemType Directory -Path "$basePath/$_" -Force | Out-Null
        }
        
        # Package.json
        $package = @{
            name = "@bushido/backend"
            version = "1.0.0"
            private = $true
            type = "module"
            scripts = @{
                "dev" = "nodemon src/index.ts"
                "build" = "tsc"
                "start" = "node dist/index.js"
            }
            dependencies = @{
                "express" = "^4.18.2"
                "cors" = "^2.8.5"
                "ethers" = "^6.10.0"
            }
            devDependencies = @{
                "@types/express" = "^4.17.21"
                "typescript" = "^5.3.3"
                "nodemon" = "^3.0.2"
                "ts-node" = "^10.9.2"
            }
        }
        
        [FileOperation]::WriteJson("$basePath/package.json", $package)
        
        $logger.Log("Backend package created", "Success")
    }
}

class ScriptsBuilder {
    static [void] Create([Logger]$logger) {
        $logger.Log("Creating scripts package", "Info")
        
        $basePath = "scripts"
        New-Item -ItemType Directory -Path $basePath -Force | Out-Null
        
        # Package.json
        $package = @{
            name = "@bushido/scripts"
            version = "1.0.0"
            private = $true
            scripts = @{
                "generate-metadata" = "ts-node src/generate-metadata.ts"
            }
            devDependencies = @{
                "typescript" = "^5.3.3"
                "ts-node" = "^10.9.2"
            }
        }
        
        [FileOperation]::WriteJson("$basePath/package.json", $package)
        
        $logger.Log("Scripts package created", "Success")
    }
}

class ConfigurationBuilder {
    static [void] Create([Logger]$logger) {
        $logger.Log("Creating configuration files", "Info")
        
        # .gitignore
        $gitignore = @"
# Dependencies
node_modules/
.pnpm-store/

# Build
.next/
dist/
build/
artifacts/
cache/

# Environment
.env
.env*.local

# Logs
logs/
*.log

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db
"@
        
        [FileOperation]::WriteFile(".gitignore", $gitignore)
        
        # .env.example
        $env = @"
# Network
ABSTRACT_RPC=https://api.abs.xyz
ABSTRACT_TESTNET_RPC=https://api.testnet.abs.xyz
PRIVATE_KEY=

# Contract
CONTRACT_ADDRESS=
IPFS_BASE_URI=

# Frontend
NEXT_PUBLIC_NETWORK=abstract
NEXT_PUBLIC_CONTRACT_ADDRESS=
"@
        
        [FileOperation]::WriteFile(".env.example", $env)
        
        # README.md
        $readme = @"
# 🏯 Bushido NFT - Interactive Anime Storytelling

> *"Eight clans. Eight virtues. One destiny."*

An innovative NFT project combining digital collectibles with episodic anime storytelling, where holders shape the narrative through on-chain voting.

## 🚀 Quick Start

\`\`\`bash
# Install dependencies
pnpm install

# Configure environment
cp .env.example .env

# Deploy to testnet
pnpm deploy:testnet

# Start development
pnpm dev
\`\`\`

## 🎭 The Eight Clans

$(
    [BushidoConstants]::Clans | ForEach-Object {
        "$($_.Id + 1). **$($_.Name)** ($($_.Symbol)) - $($_.Virtue)"
    } | Out-String
)

## 📄 License

MIT License
"@
        
        [FileOperation]::WriteFile("README.md", $readme)
        
        $logger.Log("Configuration files created", "Success")
    }
}

# ═══════════════════════════════════════════════════════════════════
# Prerequisite Validation
# ═══════════════════════════════════════════════════════════════════

class PrerequisiteValidator {
    static [hashtable] $Requirements = @{
        node = @{
            Command = "node --version"
            Pattern = "v(\d+)\.(\d+)\.(\d+)"
            MinVersion = [Version]"18.0.0"
            ErrorMsg = "Node.js 18+ required. Install from https://nodejs.org"
        }
        pnpm = @{
            Command = "pnpm --version"
            Pattern = "(\d+)\.(\d+)\.(\d+)"
            MinVersion = [Version]"8.0.0"
            ErrorMsg = "pnpm 8+ required. Install with: npm install -g pnpm"
        }
        git = @{
            Command = "git --version"
            Pattern = "(\d+)\.(\d+)\.(\d+)"
            MinVersion = [Version]"2.0.0"
            ErrorMsg = "Git required. Install from https://git-scm.com"
        }
    }
    
    static [bool] Validate([Logger]$logger) {
        $logger.Log("Validating prerequisites", "Info")
        $valid = $true
        
        foreach ($tool in [PrerequisiteValidator]::Requirements.GetEnumerator()) {
            try {
                $output = Invoke-Expression $tool.Value.Command 2>&1 | Out-String
                
                if ($output -match $tool.Value.Pattern) {
                    $major = [int]$Matches[1]
                    $minor = [int]$Matches[2]
                    $patch = [int]$Matches[3]
                    $version = [Version]::new($major, $minor, $patch)
                    
                    if ($version -ge $tool.Value.MinVersion) {
                        $logger.Log("✓ $($tool.Key) $version", "Success")
                    } else {
                        $logger.Log("$($tool.Key) version $version is below minimum", "Error")
                        $logger.Log($tool.Value.ErrorMsg, "Warning")
                        $valid = $false
                    }
                } else {
                    throw "Version pattern not matched"
                }
            }
            catch {
                $logger.Log("$($tool.Key) not found", "Error")
                $logger.Log($tool.Value.ErrorMsg, "Warning")
                $valid = $false
            }
        }
        
        return $valid
    }
}

# ═══════════════════════════════════════════════════════════════════
# Main Orchestrator
# ═══════════════════════════════════════════════════════════════════

class ProjectOrchestrator {
    [string]$ProjectPath
    [Logger]$Logger
    
    ProjectOrchestrator([string]$projectPath, [string]$logLevel) {
        $this.ProjectPath = $projectPath
        $this.Logger = [Logger]::new($logLevel, $projectPath)
    }
    
    [bool] Execute([bool]$skipPrerequisites) {
        try {
            # Change to project directory
            if ($this.ProjectPath -ne (Get-Location).Path) {
                New-Item -ItemType Directory -Path $this.ProjectPath -Force | Out-Null
                Set-Location $this.ProjectPath
            }
            
            # Validate prerequisites
            if (-not $skipPrerequisites) {
                if (-not [PrerequisiteValidator]::Validate($this.Logger)) {
                    return $false
                }
            }
            
            # Build project structure
            [RootStructureBuilder]::Create($this.Logger)
            [ContractsBuilder]::Create($this.Logger)
            [FrontendBuilder]::Create($this.Logger)
            [BackendBuilder]::Create($this.Logger)
            [ScriptsBuilder]::Create($this.Logger)
            [ConfigurationBuilder]::Create($this.Logger)
            
            return $true
        }
        catch {
            $this.Logger.Log("Fatal error: $_", "Error", @{
                StackTrace = $_.ScriptStackTrace
            })
            return $false
        }
    }
    
    [void] Dispose() {
        $this.Logger.Dispose()
    }
}

# ═══════════════════════════════════════════════════════════════════
# CLI Functions
# ═══════════════════════════════════════════════════════════════════

function Show-Banner {
    Clear-Host
    Write-Host @"

    ██████╗ ██╗   ██╗███████╗██╗  ██╗██╗██████╗  ██████╗ 
    ██╔══██╗██║   ██║██╔════╝██║  ██║██║██╔══██╗██╔═══██╗
    ██████╔╝██║   ██║███████╗███████║██║██║  ██║██║   ██║
    ██╔══██╗██║   ██║╚════██║██╔══██║██║██║  ██║██║   ██║
    ██████╔╝╚██████╔╝███████║██║  ██║██║██████╔╝╚██████╔╝
    ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝ 
                                                            
           Interactive NFT Anime • Web3 Storytelling
                    
"@ -ForegroundColor Red
    
    Write-Host "    🥷 Stealth Launch Edition | Abstract L2 Ready" -ForegroundColor Magenta
    Write-Host "    ═══════════════════════════════════════════════════`n" -ForegroundColor DarkRed
}

function Show-Configuration {
    Write-Host "    📋 Project Configuration:" -ForegroundColor Yellow
    Write-Host "       Supply:      " -NoNewline -ForegroundColor White
    Write-Host "$([BushidoConstants]::Project.TotalSupply) NFTs" -ForegroundColor DarkGray
    Write-Host "       Structure:   " -NoNewline -ForegroundColor White
    Write-Host "$([BushidoConstants]::Project.ClansCount) clans × $([BushidoConstants]::Project.TokensPerClan) tokens" -ForegroundColor DarkGray
    Write-Host "       Price:       " -NoNewline -ForegroundColor White
    Write-Host "$([BushidoConstants]::Project.MintPrice) ETH" -ForegroundColor DarkGray
    Write-Host "       Blockchain:  " -NoNewline -ForegroundColor White
    Write-Host "$([BushidoConstants]::Project.Blockchain)" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "    🏯 The Eight Clans:" -ForegroundColor Cyan
    [BushidoConstants]::Clans | ForEach-Object {
        Write-Host "       $($_.Symbol) " -NoNewline
        Write-Host "$($_.Name.PadRight(10))" -NoNewline -ForegroundColor White
        Write-Host "- $($_.Virtue)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Show-Success {
    Write-Host "`n    ✨ " -NoNewline -ForegroundColor Magenta
    Write-Host "SETUP COMPLETE!" -ForegroundColor White
    Write-Host "    ═══════════════════════════════════════════════════" -ForegroundColor DarkGreen
    
    Write-Host "`n    🚀 Next Steps:" -ForegroundColor Cyan
    Write-Host "       1. Install dependencies:    " -NoNewline -ForegroundColor White
    Write-Host "pnpm install" -ForegroundColor Yellow
    Write-Host "       2. Configure environment:   " -NoNewline -ForegroundColor White
    Write-Host "cp .env.example .env" -ForegroundColor Yellow
    Write-Host "       3. Deploy to testnet:       " -NoNewline -ForegroundColor White
    Write-Host "pnpm deploy:testnet" -ForegroundColor Yellow
    Write-Host "       4. Start development:       " -NoNewline -ForegroundColor White
    Write-Host "pnpm dev`n" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════════════
# Main Entry Point
# ═══════════════════════════════════════════════════════════════════

Show-Banner
Show-Configuration

$orchestrator = $null

try {
    $orchestrator = [ProjectOrchestrator]::new($ProjectPath, $LogLevel)
    
    Write-Host "    🔨 Building project structure..." -ForegroundColor Cyan
    Write-Host ""
    
    if ($orchestrator.Execute($SkipPrerequisites)) {
        Show-Success
    } else {
        Write-Host "`n    ❌ Setup failed. Check the log file for details.`n" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "`n    💥 Fatal Error: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    exit 1
}
finally {
    $orchestrator?.Dispose()
}