# BushidoProjectGenesis.ps1
# An architectural symphony for project initialization
# Demonstrating advanced patterns, reactive programming, and exceptional elegance

#Requires -Version 7.0
using namespace System.Management.Automation
using namespace System.Collections.Concurrent
using namespace System.Threading.Tasks
using namespace System.Reactive.Linq
using namespace System.Reactive.Subjects

# ═══════════════════════════════════════════════════════════════════
# Core Architectural Abstractions
# ═══════════════════════════════════════════════════════════════════

# Immutable configuration with builder pattern
class BushidoProjectConfiguration {
    [string]$ProjectRoot
    [string]$ProjectName = "bushido-nft"
    [hashtable]$PackageVersions
    [hashtable]$WorkspacePackages
    [System.Collections.Generic.List[string]]$FeatureFlags
    hidden [bool]$_immutable = $false
    
    BushidoProjectConfiguration() {
        $this.ProjectRoot = Get-Location
        $this.PackageVersions = @{
            "next" = "14.1.0"
            "react" = "^18.2.0"
            "typescript" = "^5.3.3"
            "wagmi" = "^2.5.7"
            "viem" = "^2.7.6"
            "@rainbow-me/rainbowkit" = "^2.0.0"
            "hardhat" = "^2.19.4"
            "@openzeppelin/contracts" = "^5.0.1"
        }
        $this.WorkspacePackages = @{
            "contracts" = @{ 
                name = "@bushido/contracts"
                type = "smart-contracts"
                framework = "hardhat"
            }
            "frontend" = @{ 
                name = "@bushido/frontend"
                type = "web-app"
                framework = "next.js"
            }
            "backend" = @{ 
                name = "@bushido/backend"
                type = "api-server"
                framework = "express"
            }
            "scripts" = @{ 
                name = "@bushido/scripts"
                type = "tooling"
                framework = "node"
            }
        }
        $this.FeatureFlags = [System.Collections.Generic.List[string]]::new()
        $this.FeatureFlags.AddRange(@(
            "STEALTH_LAUNCH",
            "ABSTRACT_L2",
            "VOTING_SYSTEM",
            "IPFS_METADATA",
            "EPISODE_STREAMING"
        ))
    }
    
    [BushidoProjectConfiguration] MakeImmutable() {
        $this._immutable = $true
        return $this
    }
    
    [void] ValidateImmutability() {
        if ($this._immutable) {
            throw [System.InvalidOperationException]::new("Configuration is immutable")
        }
    }
}

# Advanced logging with reactive streams
class ReactiveLogger {
    hidden [Subject[LogEvent]]$LogStream
    hidden [System.IDisposable[]]$Subscriptions
    hidden [string]$LogPath
    hidden [ConcurrentQueue[LogEvent]]$LogBuffer
    hidden [System.Threading.Timer]$FlushTimer
    
    ReactiveLogger([string]$logPath) {
        $this.LogPath = $logPath
        $this.LogStream = [Subject[LogEvent]]::new()
        $this.LogBuffer = [ConcurrentQueue[LogEvent]]::new()
        $this.Subscriptions = @()
        $this.InitializeStreams()
        $this.InitializeFlushTimer()
    }
    
    hidden [void] InitializeStreams() {
        # Console output stream with throttling
        $consoleSubscription = $this.LogStream
            | Where-Object { $_.Level -ne "Debug" -or $script:VerbosePreference -eq "Continue" }
            | Buffer -TimeSpan ([TimeSpan]::FromMilliseconds(50))
            | Where-Object { $_.Count -gt 0 }
            | Subscribe -Action {
                param($events)
                $events | ForEach-Object { $this.WriteToConsole($_) }
            }
        
        # File output stream with batching
        $fileSubscription = $this.LogStream
            | Buffer -Count 10 -TimeSpan ([TimeSpan]::FromSeconds(1))
            | Where-Object { $_.Count -gt 0 }
            | Subscribe -Action {
                param($events)
                $this.WriteToFile($events)
            }
        
        # Metrics collection stream
        $metricsSubscription = $this.LogStream
            | Where-Object { $_.Metrics -ne $null }
            | Scan -Seed @{} -Accumulator {
                param($acc, $event)
                $acc[$event.Metrics.Name] = $event.Metrics.Value
                return $acc
            }
            | Subscribe -Action {
                param($metrics)
                $script:ProjectMetrics = $metrics
            }
        
        $this.Subscriptions = @($consoleSubscription, $fileSubscription, $metricsSubscription)
    }
    
    hidden [void] InitializeFlushTimer() {
        $callback = {
            $event = [LogEvent]::new()
            while ($this.LogBuffer.TryDequeue([ref]$event)) {
                $this.LogStream.OnNext($event)
            }
        }
        $this.FlushTimer = [System.Threading.Timer]::new($callback, $null, 100, 100)
    }
    
    [void] Log([string]$message, [LogLevel]$level = [LogLevel]::Info, [hashtable]$context = @{}) {
        $event = [LogEvent]::new($message, $level, $context)
        $this.LogBuffer.Enqueue($event)
    }
    
    hidden [void] WriteToConsole([LogEvent]$event) {
        $colors = @{
            [LogLevel]::Debug = "DarkGray"
            [LogLevel]::Info = "Cyan"
            [LogLevel]::Success = "Green"
            [LogLevel]::Warning = "Yellow"
            [LogLevel]::Error = "Red"
            [LogLevel]::Critical = "DarkRed"
        }
        
        $symbols = @{
            [LogLevel]::Debug = "🔍"
            [LogLevel]::Info = "ℹ️"
            [LogLevel]::Success = "✅"
            [LogLevel]::Warning = "⚠️"
            [LogLevel]::Error = "❌"
            [LogLevel]::Critical = "🚨"
        }
        
        $timestamp = $event.Timestamp.ToString("HH:mm:ss.fff")
        $indent = "  " * $event.Context.IndentLevel
        
        Write-Host "$indent[$timestamp] " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($symbols[$event.Level]) " -NoNewline
        Write-Host $event.Message -ForegroundColor $colors[$event.Level]
    }
    
    hidden [void] WriteToFile([LogEvent[]]$events) {
        $logEntries = $events | ForEach-Object {
            $_.ToJson()
        }
        Add-Content -Path $this.LogPath -Value ($logEntries -join "`n") -Encoding UTF8
    }
    
    [void] Dispose() {
        $this.FlushTimer?.Dispose()
        $this.Subscriptions | ForEach-Object { $_?.Dispose() }
        $this.LogStream?.Dispose()
    }
}

# Event sourcing for project state
class ProjectEvent {
    [string]$Id
    [string]$Type
    [datetime]$Timestamp
    [hashtable]$Data
    [string]$CorrelationId
    
    ProjectEvent([string]$type, [hashtable]$data) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Type = $type
        $this.Timestamp = [datetime]::UtcNow
        $this.Data = $data
        $this.CorrelationId = $script:CorrelationId
    }
}

# Sophisticated project builder with transactional support
class ProjectBuilder {
    hidden [ReactiveLogger]$Logger
    hidden [BushidoProjectConfiguration]$Config
    hidden [System.Collections.Generic.List[ProjectEvent]]$EventStore
    hidden [System.Collections.Generic.Stack[Action]]$RollbackStack
    hidden [hashtable]$BuildContext
    
    ProjectBuilder([ReactiveLogger]$logger, [BushidoProjectConfiguration]$config) {
        $this.Logger = $logger
        $this.Config = $config.MakeImmutable()
        $this.EventStore = [System.Collections.Generic.List[ProjectEvent]]::new()
        $this.RollbackStack = [System.Collections.Generic.Stack[Action]]::new()
        $this.BuildContext = @{
            StartTime = [datetime]::UtcNow
            CreatedArtifacts = [System.Collections.Generic.List[string]]::new()
            Metrics = @{}
        }
    }
    
    # Fluent builder methods with automatic rollback registration
    [ProjectBuilder] CreateWorkspaceStructure() {
        $this.Logger.Log("Initializing workspace architecture", [LogLevel]::Info, @{ IndentLevel = 0 })
        
        try {
            # Create root configuration
            $this.ExecuteWithRollback(
                {
                    $this.Logger.Log("Configuring pnpm workspace", [LogLevel]::Info, @{ IndentLevel = 1 })
                    
                    # Root package.json with sophisticated scripts
                    $rootPackage = [ordered]@{
                        name = $this.Config.ProjectName
                        version = "1.0.0"
                        private = $true
                        type = "module"
                        engines = @{
                            node = ">=18.0.0"
                            pnpm = ">=8.0.0"
                        }
                        scripts = [ordered]@{
                            # Development orchestration
                            "dev" = "turbo run dev --parallel"
                            "dev:contracts" = "pnpm --filter @bushido/contracts dev"
                            "dev:frontend" = "pnpm --filter @bushido/frontend dev"
                            "dev:backend" = "pnpm --filter @bushido/backend dev"
                            
                            # Build pipeline
                            "build" = "turbo run build"
                            "build:contracts" = "turbo run build --filter=@bushido/contracts"
                            "build:production" = "turbo run build --filter=!@bushido/scripts"
                            
                            # Testing orchestration
                            "test" = "turbo run test"
                            "test:unit" = "turbo run test:unit"
                            "test:integration" = "turbo run test:integration"
                            "test:e2e" = "turbo run test:e2e --filter=@bushido/frontend"
                            
                            # Deployment pipeline
                            "deploy:testnet" = "turbo run deploy --filter=@bushido/contracts -- --network abstract-testnet"
                            "deploy:mainnet" = "turbo run deploy --filter=@bushido/contracts -- --network abstract"
                            "deploy:frontend" = "turbo run deploy --filter=@bushido/frontend"
                            
                            # Code quality
                            "lint" = "turbo run lint"
                            "format" = "prettier --write '**/*.{js,jsx,ts,tsx,json,sol,md}'"
                            "typecheck" = "turbo run typecheck"
                            
                            # Utilities
                            "clean" = "turbo run clean && rimraf node_modules"
                            "prepare" = "husky install"
                            "changeset" = "changeset"
                            "version" = "changeset version"
                            "release" = "turbo run build && changeset publish"
                        }
                        devDependencies = [ordered]@{
                            "turbo" = "^1.12.4"
                            "prettier" = "^3.2.5"
                            "eslint" = "^8.56.0"
                            "husky" = "^9.0.10"
                            "lint-staged" = "^15.2.0"
                            "@changesets/cli" = "^2.27.1"
                            "rimraf" = "^5.0.5"
                        }
                    }
                    
                    $this.WriteJsonFile("package.json", $rootPackage)
                    pnpm init -y | Out-Null
                    
                    # Workspace configuration
                    $workspaceYaml = @"
packages:
  - 'contracts'
  - 'frontend' 
  - 'backend'
  - 'scripts'
"@
                    $this.WriteFile("pnpm-workspace.yaml", $workspaceYaml)
                    
                    # Turbo configuration for build optimization
                    $turboConfig = [ordered]@{
                        '$schema' = "https://turbo.build/schema.json"
                        globalDependencies = @(".env")
                        pipeline = [ordered]@{
                            build = @{
                                dependsOn = @("^build")
                                outputs = @("dist/**", ".next/**", "artifacts/**")
                            }
                            test = @{
                                dependsOn = @("build")
                                outputs = @()
                            }
                            lint = @{
                                outputs = @()
                            }
                            dev = @{
                                cache = $false
                                persistent = $true
                            }
                            deploy = @{
                                dependsOn = @("build", "test")
                                cache = $false
                            }
                        }
                    }
                    $this.WriteJsonFile("turbo.json", $turboConfig)
                    
                    $this.RecordEvent("WorkspaceCreated", @{ 
                        Files = @("package.json", "pnpm-workspace.yaml", "turbo.json")
                    })
                },
                {
                    # Rollback action
                    @("package.json", "pnpm-workspace.yaml", "turbo.json") | ForEach-Object {
                        Remove-Item $_ -Force -ErrorAction SilentlyContinue
                    }
                }
            )
            
            # Create sophisticated development tooling
            $this.CreateDevelopmentTooling()
            
        }
        catch {
            $this.Logger.Log("Failed to create workspace: $_", [LogLevel]::Error)
            throw
        }
        
        return $this
    }
    
    [ProjectBuilder] CreateContractsPackage() {
        $this.Logger.Log("Architecting smart contracts package", [LogLevel]::Info, @{ IndentLevel = 0 })
        
        $contractsPath = Join-Path $this.Config.ProjectRoot "contracts"
        
        $this.ExecuteWithRollback(
            {
                New-Item -ItemType Directory -Path $contractsPath -Force | Out-Null
                Push-Location $contractsPath
                
                try {
                    # Sophisticated package configuration
                    $packageConfig = [ordered]@{
                        name = "@bushido/contracts"
                        version = "1.0.0"
                        private = $true
                        type = "module"
                        scripts = [ordered]@{
                            "compile" = "hardhat compile"
                            "test" = "hardhat test"
                            "test:coverage" = "hardhat coverage"
                            "deploy" = "hardhat run scripts/deploy.ts"
                            "verify" = "hardhat verify"
                            "clean" = "hardhat clean && rimraf artifacts cache coverage typechain-types"
                            "typechain" = "hardhat typechain"
                            "size" = "hardhat size-contracts"
                            "gas-report" = "REPORT_GAS=true hardhat test"
                        }
                        devDependencies = [ordered]@{
                            "@nomicfoundation/hardhat-toolbox" = "^4.0.0"
                            "@openzeppelin/contracts" = "^5.0.1"
                            "@openzeppelin/contracts-upgradeable" = "^5.0.1"
                            "hardhat" = "^2.19.4"
                            "hardhat-contract-sizer" = "^2.10.0"
                            "hardhat-gas-reporter" = "^1.0.9"
                            "solidity-coverage" = "^0.8.5"
                            "@typechain/hardhat" = "^9.1.0"
                            "typescript" = "^5.3.3"
                            "dotenv" = "^16.3.1"
                        }
                    }
                    
                    $this.WriteJsonFile("package.json", $packageConfig)
                    
                    # Advanced Hardhat configuration
                    $hardhatConfig = @'
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import * as dotenv from "dotenv";

dotenv.config({ path: "../.env" });

// Advanced configuration with multiple networks and optimizations
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
        details: {
          yul: true,
          yulDetails: {
            stackAllocation: true,
            optimizerSteps: "dhfoDgvulfnTUtnIf"
          }
        }
      },
      viaIR: true,
      metadata: {
        bytecodeHash: "none"
      }
    }
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      chainId: 1337,
      mining: {
        auto: true,
        interval: 0
      }
    },
    abstractTestnet: {
      url: process.env.ABSTRACT_TESTNET_RPC || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11124,
      gasPrice: "auto",
      gasMultiplier: 1.2
    },
    abstract: {
      url: process.env.ABSTRACT_MAINNET_RPC || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11125,
      gasPrice: "auto",
      gasMultiplier: 1.1
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    currency: "USD",
    gasPrice: 20,
    token: "ETH",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    excludeContracts: [],
    src: "./contracts"
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true
  },
  etherscan: {
    apiKey: {
      abstract: process.env.ABSTRACT_EXPLORER_API_KEY || ""
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 40000
  }
};

export default config;
'@
                    $this.WriteFile("hardhat.config.ts", $hardhatConfig)
                    
                    # Create the main NFT contract with sophisticated patterns
                    $this.CreateBushidoNFTContract($contractsPath)
                    
                    # Create deployment scripts
                    $this.CreateDeploymentScripts($contractsPath)
                    
                    # Create comprehensive test suite
                    $this.CreateContractTests($contractsPath)
                    
                    $this.RecordEvent("ContractsPackageCreated", @{ 
                        Path = $contractsPath
                        Framework = "hardhat"
                    })
                }
                finally {
                    Pop-Location
                }
            },
            {
                Remove-Item $contractsPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        )
        
        return $this
    }
    
    [ProjectBuilder] CreateFrontendPackage() {
        $this.Logger.Log("Crafting Next.js frontend architecture", [LogLevel]::Info, @{ IndentLevel = 0 })
        
        $frontendPath = Join-Path $this.Config.ProjectRoot "frontend"
        
        $this.ExecuteWithRollback(
            {
                # Create Next.js app with our specifications
                $this.Logger.Log("Initializing Next.js with TypeScript and Tailwind", [LogLevel]::Info, @{ IndentLevel = 1 })
                
                $createCommand = "pnpm create next-app@latest frontend --typescript --tailwind --app --src-dir --import-alias '@/*' --no-git --yes"
                Invoke-Expression $createCommand | Out-Null
                
                Push-Location $frontendPath
                
                try {
                    # Enhance package.json with additional dependencies
                    $packagePath = "package.json"
                    $package = Get-Content $packagePath -Raw | ConvertFrom-Json
                    
                    # Add sophisticated dependencies
                    $additionalDeps = [ordered]@{
                        # Web3 stack
                        "wagmi" = "^2.5.7"
                        "viem" = "^2.7.6"
                        "@rainbow-me/rainbowkit" = "^2.0.0"
                        "ethers" = "^6.10.0"
                        
                        # 3D and animations
                        "@react-three/fiber" = "^8.15.12"
                        "@react-three/drei" = "^9.96.1"
                        "@react-three/postprocessing" = "^2.15.11"
                        "three" = "^0.160.0"
                        "framer-motion" = "^11.0.3"
                        "leva" = "^0.9.35"
                        
                        # UI and state
                        "lucide-react" = "^0.312.0"
                        "zustand" = "^4.4.7"
                        "@tanstack/react-query" = "^5.17.9"
                        "react-hook-form" = "^7.48.2"
                        "zod" = "^3.22.4"
                        
                        # Utilities
                        "axios" = "^1.6.5"
                        "date-fns" = "^3.3.1"
                        "clsx" = "^2.1.0"
                        "tailwind-merge" = "^2.2.0"
                    }
                    
                    foreach ($dep in $additionalDeps.GetEnumerator()) {
                        if (-not $package.dependencies.PSObject.Properties[$dep.Key]) {
                            $package.dependencies | Add-Member -MemberType NoteProperty -Name $dep.Key -Value $dep.Value -Force
                        }
                    }
                    
                    # Add sophisticated scripts
                    $package.scripts | Add-Member -MemberType NoteProperty -Name "analyze" -Value "ANALYZE=true next build" -Force
                    $package.scripts | Add-Member -MemberType NoteProperty -Name "typecheck" -Value "tsc --noEmit" -Force
                    $package.scripts | Add-Member -MemberType NoteProperty -Name "test" -Value "vitest" -Force
                    $package.scripts | Add-Member -MemberType NoteProperty -Name "test:ui" -Value "vitest --ui" -Force
                    
                    $this.WriteJsonFile($packagePath, $package)
                    
                    # Create sophisticated project structure
                    $this.CreateFrontendArchitecture($frontendPath)
                    
                    # Create advanced configuration files
                    $this.CreateFrontendConfiguration($frontendPath)
                    
                    $this.RecordEvent("FrontendPackageCreated", @{ 
                        Path = $frontendPath
                        Framework = "next.js"
                    })
                }
                finally {
                    Pop-Location
                }
            },
            {
                Remove-Item $frontendPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        )
        
        return $this
    }
    
    # Advanced helper methods
    hidden [void] CreateBushidoNFTContract([string]$contractsPath) {
        $contractDir = Join-Path $contractsPath "contracts"
        New-Item -ItemType Directory -Path $contractDir -Force | Out-Null
        
        # Main NFT contract with sophisticated features
        $nftContract = @'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IBushidoNFT.sol";
import "./libraries/VotingPower.sol";

/**
 * @title BushidoNFT
 * @author Bushido Development Team
 * @notice Sophisticated NFT contract with integrated voting mechanics
 * @dev Implements ERC721 with enumerable extension and custom voting logic
 */
contract BushidoNFT is 
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ReentrancyGuard,
    AccessControl,
    IBushidoNFT 
{
    using Counters for Counters.Counter;
    using VotingPower for uint256;
    
    // ═══════════════════════════════════════════════════════════════════
    // State Variables
    // ═══════════════════════════════════════════════════════════════════
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant EPISODE_MANAGER_ROLE = keccak256("EPISODE_MANAGER_ROLE");
    
    uint256 public constant MAX_SUPPLY = 1600;
    uint256 public constant TOKENS_PER_CLAN = 200;
    uint256 public constant MINT_PRICE = 0.08 ether;
    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public constant CLAN_COUNT = 8;
    
    Counters.Counter private _tokenIdCounter;
    
    // Sophisticated mappings for metadata and voting
    mapping(uint256 => TokenMetadata) private _tokenMetadata;
    mapping(uint256 => uint256) public tokenVotingPower;
    mapping(address => uint256) public mintedPerWallet;
    mapping(uint256 => mapping(uint256 => bool)) public hasVotedInEpisode;
    mapping(uint256 => mapping(uint256 => uint256)) public episodeVotes;
    
    // Clan names for the eight virtues
    string[8] public clanNames = [
        "Dragon", "Phoenix", "Tiger", "Serpent",
        "Eagle", "Wolf", "Bear", "Lion"
    ];
    
    // Contract state
    bool public mintActive;
    string private _baseTokenURI;
    uint256 public currentEpisode = 1;
    
    // ═══════════════════════════════════════════════════════════════════
    // Events
    // ═══════════════════════════════════════════════════════════════════
    
    event MintActivated(uint256 timestamp);
    event TokenMinted(
        address indexed to,
        uint256 indexed tokenId,
        uint256 clan,
        uint256 rarity
    );
    event VoteCast(
        uint256 indexed tokenId,
        uint256 indexed episodeId,
        uint256 choice,
        uint256 votingPower
    );
    event EpisodeAdvanced(uint256 newEpisode);
    
    // ═══════════════════════════════════════════════════════════════════
    // Constructor
    // ═══════════════════════════════════════════════════════════════════
    
    constructor(string memory baseURI) ERC721("Bushido", "BUSHIDO") {
        _baseTokenURI = baseURI;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(EPISODE_MANAGER_ROLE, msg.sender);
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // Minting Functions
    // ═══════════════════════════════════════════════════════════════════
    
    function activateMint() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!mintActive, "Mint already active");
        mintActive = true;
        emit MintActivated(block.timestamp);
    }
    
    function mint(uint256 quantity) 
        external 
        payable 
        nonReentrant 
    {
        require(mintActive, "Mint not active");
        require(quantity > 0 && quantity <= MAX_PER_WALLET, "Invalid quantity");
        require(
            mintedPerWallet[msg.sender] + quantity <= MAX_PER_WALLET,
            "Exceeds wallet limit"
        );
        require(
            _tokenIdCounter.current() + quantity <= MAX_SUPPLY,
            "Exceeds max supply"
        );
        require(msg.value >= MINT_PRICE * quantity, "Insufficient payment");
        
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            
            // Determine clan and rarity
            uint256 clan = ((tokenId - 1) / TOKENS_PER_CLAN) + 1;
            uint256 rarity = _generateRarity(tokenId);
            
            // Store metadata
            _tokenMetadata[tokenId] = TokenMetadata({
                clan: clan,
                rarity: rarity,
                generation: 1,
                evolutionStage: 0
            });
            
            // Calculate and store voting power
            tokenVotingPower[tokenId] = rarity.calculateVotingPower();
            
            // Mint token
            _safeMint(msg.sender, tokenId);
            
            emit TokenMinted(msg.sender, tokenId, clan, rarity);
        }
        
        mintedPerWallet[msg.sender] += quantity;
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // Voting System
    // ═══════════════════════════════════════════════════════════════════
    
    function castVote(uint256 tokenId, uint256 choice) 
        external 
        nonReentrant 
    {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        require(!hasVotedInEpisode[tokenId][currentEpisode], "Already voted");
        require(choice > 0 && choice <= 4, "Invalid choice");
        
        hasVotedInEpisode[tokenId][currentEpisode] = true;
        uint256 votePower = tokenVotingPower[tokenId];
        episodeVotes[currentEpisode][choice] += votePower;
        
        emit VoteCast(tokenId, currentEpisode, choice, votePower);
    }
    
    function getTotalVotingPower(address wallet) 
        external 
        view 
        returns (uint256 total) 
    {
        uint256 balance = balanceOf(wallet);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(wallet, i);
            total += tokenVotingPower[tokenId];
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // Internal Functions
    // ═══════════════════════════════════════════════════════════════════
    
    function _generateRarity(uint256 tokenId) 
        private 
        view 
        returns (uint256) 
    {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    tokenId,
                    msg.sender
                )
            )
        );
        
        uint256 rand = seed % 100;
        
        if (rand < 1) return 5;  // Legendary (1%)
        if (rand < 5) return 4;  // Epic (4%)
        if (rand < 15) return 3; // Rare (10%)
        if (rand < 35) return 2; // Uncommon (20%)
        return 1;                // Common (65%)
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // Required Overrides
    // ═══════════════════════════════════════════════════════════════════
    
    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }
    
    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
'@
        $this.WriteFile(
            (Join-Path $contractDir "BushidoNFT.sol"),
            $nftContract
        )
        
        # Create sophisticated interfaces
        $interfaceDir = Join-Path $contractDir "interfaces"
        New-Item -ItemType Directory -Path $interfaceDir -Force | Out-Null
        
        $interface = @'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBushidoNFT {
    struct TokenMetadata {
        uint256 clan;
        uint256 rarity;
        uint256 generation;
        uint256 evolutionStage;
    }
    
    function castVote(uint256 tokenId, uint256 choice) external;
    function getTotalVotingPower(address wallet) external view returns (uint256);
    function tokenVotingPower(uint256 tokenId) external view returns (uint256);
}
'@
        $this.WriteFile(
            (Join-Path $interfaceDir "IBushidoNFT.sol"),
            $interface
        )
        
        # Create library for voting calculations
        $libDir = Join-Path $contractDir "libraries"
        New-Item -ItemType Directory -Path $libDir -Force | Out-Null
        
        $votingLib = @'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library VotingPower {
    function calculateVotingPower(uint256 rarity) internal pure returns (uint256) {
        // Exponential voting power based on rarity
        return rarity ** 2;
    }
}
'@
        $this.WriteFile(
            (Join-Path $libDir "VotingPower.sol"),
            $votingLib
        )
    }
    
    hidden [void] CreateFrontendArchitecture([string]$frontendPath) {
        # Create sophisticated directory structure
        $directories = @(
            "src/components/stealth-launch",
            "src/components/mint",
            "src/components/episodes",
            "src/components/voting",
            "src/components/three",
            "src/components/ui",
            "src/hooks",
            "src/lib/web3",
            "src/lib/api",
            "src/lib/state",
            "src/lib/utils",
            "src/styles",
            "src/types",
            "public/videos",
            "public/models",
            "public/images/clans",
            "public/images/rarities"
        )
        
        $directories | ForEach-Object {
            New-Item -ItemType Directory -Path (Join-Path $frontendPath $_) -Force | Out-Null
        }
        
        # Create sophisticated wagmi configuration
        $wagmiConfig = @'
import { createConfig, configureChains } from 'wagmi'
import { abstractTestnet, abstract } from 'wagmi/chains'
import { alchemyProvider } from 'wagmi/providers/alchemy'
import { publicProvider } from 'wagmi/providers/public'
import { getDefaultWallets, RainbowKitProvider } from '@rainbow-me/rainbowkit'

const { chains, publicClient, webSocketPublicClient } = configureChains(
  [
    process.env.NEXT_PUBLIC_NETWORK === 'mainnet' ? abstract : abstractTestnet
  ],
  [
    alchemyProvider({ apiKey: process.env.NEXT_PUBLIC_ALCHEMY_KEY! }),
    publicProvider()
  ]
)

const { connectors } = getDefaultWallets({
  appName: 'Bushido NFT',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID!,
  chains
})

export const wagmiConfig = createConfig({
  autoConnect: true,
  connectors,
  publicClient,
  webSocketPublicClient,
})

export { chains }
'@
        $this.WriteFile(
            (Join-Path $frontendPath "src/lib/web3/wagmi.ts"),
            $wagmiConfig
        )
        
        # Create zustand store for state management
        $storeConfig = @'
import { create } from 'zustand'
import { devtools, persist } from 'zustand/middleware'
import { immer } from 'zustand/middleware/immer'

interface BushidoState {
  // Launch state
  isStealthMode: boolean
  launchTime: Date | null
  
  // Mint state
  mintedTokens: number[]
  selectedClan: number | null
  
  // Episode state
  currentEpisode: number
  votingDeadline: Date | null
  userVotes: Record<number, number>
  
  // Actions
  setStealthMode: (mode: boolean) => void
  setSelectedClan: (clan: number | null) => void
  recordVote: (episode: number, choice: number) => void
}

export const useBushidoStore = create<BushidoState>()(
  devtools(
    persist(
      immer((set) => ({
        // Initial state
        isStealthMode: true,
        launchTime: null,
        mintedTokens: [],
        selectedClan: null,
        currentEpisode: 1,
        votingDeadline: null,
        userVotes: {},
        
        // Actions with Immer for immutability
        setStealthMode: (mode) => set((state) => {
          state.isStealthMode = mode
        }),
        
        setSelectedClan: (clan) => set((state) => {
          state.selectedClan = clan
        }),
        
        recordVote: (episode, choice) => set((state) => {
          state.userVotes[episode] = choice
        })
      })),
      {
        name: 'bushido-storage',
        partialize: (state) => ({
          mintedTokens: state.mintedTokens,
          userVotes: state.userVotes
        })
      }
    )
  )
)
'@
        $this.WriteFile(
            (Join-Path $frontendPath "src/lib/state/store.ts"),
            $storeConfig
        )
    }
    
    # Transactional execution with automatic rollback
    hidden [void] ExecuteWithRollback([Action]$action, [Action]$rollback) {
        try {
            & $action
            $this.RollbackStack.Push($rollback)
        }
        catch {
            $this.Logger.Log("Executing rollback due to error: $_", [LogLevel]::Warning)
            $this.ExecuteRollback()
            throw
        }
    }
    
    hidden [void] ExecuteRollback() {
        while ($this.RollbackStack.Count -gt 0) {
            $rollback = $this.RollbackStack.Pop()
            try {
                & $rollback
            }
            catch {
                $this.Logger.Log("Rollback failed: $_", [LogLevel]::Error)
            }
        }
    }
    
    # Elegant file writing with atomic operations
    hidden [void] WriteFile([string]$path, [string]$content) {
        $directory = Split-Path -Parent $path
        if ($directory -and -not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        
        # Atomic write using temporary file
        $tempFile = "$path.tmp"
        Set-Content -Path $tempFile -Value $content -Encoding UTF8 -NoNewline
        Move-Item -Path $tempFile -Destination $path -Force
        
        $this.BuildContext.CreatedArtifacts.Add($path)
    }
    
    hidden [void] WriteJsonFile([string]$path, [object]$content) {
        $json = $content | ConvertTo-Json -Depth 10 -Compress:$false
        $this.WriteFile($path, $json)
    }
    
    hidden [void] CreateDevelopmentTooling() {
        # Git configuration
        $gitignore = @'
# Dependencies
node_modules/
.pnpm-store/

# Production
build/
dist/
out/
.next/
.nuxt/
.cache/
*.tsbuildinfo

# Environment
.env
.env*.local

# Logs
logs/
*.log
npm-debug.log*
pnpm-debug.log*
yarn-debug.log*
yarn-error.log*

# Testing
coverage/
.nyc_output/

# Contracts
artifacts/
cache/
typechain-types/
deployments/localhost/

# IDE
.idea/
.vscode/
*.swp
*.swo
*~
.DS_Store

# Misc
*.pem
.vercel
.turbo
'@
        $this.WriteFile(".gitignore", $gitignore)
        
        # Prettier configuration
        $prettierConfig = [ordered]@{
            semi = $true
            singleQuote = $true
            trailingComma = "es5"
            printWidth = 100
            tabWidth = 2
            useTabs = $false
            arrowParens = "always"
            endOfLine = "lf"
            plugins = @("prettier-plugin-solidity")
            overrides = @(
                @{
                    files = "*.sol"
                    options = @{
                        printWidth = 100
                        tabWidth = 4
                        useTabs = $false
                        singleQuote = $false
                        bracketSpacing = $false
                    }
                }
            )
        }
        $this.WriteJsonFile(".prettierrc", $prettierConfig)
        
        # ESLint configuration
        $eslintConfig = [ordered]@{
            root = $true
            extends = @(
                "eslint:recommended",
                "plugin:@typescript-eslint/recommended",
                "plugin:react/recommended",
                "plugin:react-hooks/recommended",
                "prettier"
            )
            parser = "@typescript-eslint/parser"
            parserOptions = @{
                ecmaVersion = "latest"
                sourceType = "module"
                ecmaFeatures = @{
                    jsx = $true
                }
            }
            plugins = @("@typescript-eslint", "react", "react-hooks")
            rules = @{
                "react/react-in-jsx-scope" = "off"
                "react/prop-types" = "off"
                "@typescript-eslint/explicit-module-boundary-types" = "off"
                "@typescript-eslint/no-explicit-any" = "warn"
            }
            settings = @{
                react = @{
                    version = "detect"
                }
            }
        }
        $this.WriteJsonFile(".eslintrc.json", $eslintConfig)
    }
    
    hidden [void] RecordEvent([string]$type, [hashtable]$data) {
        $event = [ProjectEvent]::new($type, $data)
        $this.EventStore.Add($event)
        
        # Update metrics
        if ($this.BuildContext.Metrics.ContainsKey($type)) {
            $this.BuildContext.Metrics[$type]++
        }
        else {
            $this.BuildContext.Metrics[$type] = 1
        }
    }
}

# Enumerations
enum LogLevel {
    Debug
    Info
    Success
    Warning
    Error
    Critical
}

class LogEvent {
    [string]$Message
    [LogLevel]$Level
    [datetime]$Timestamp
    [hashtable]$Context
    [hashtable]$Metrics
    
    LogEvent() {
        $this.Timestamp = [datetime]::UtcNow
        $this.Context = @{}
    }
    
    LogEvent([string]$message, [LogLevel]$level, [hashtable]$context) {
        $this.Message = $message
        $this.Level = $level
        $this.Timestamp = [datetime]::UtcNow
        $this.Context = $context
    }
    
    [string] ToJson() {
        return @{
            timestamp = $this.Timestamp.ToString("o")
            level = $this.Level.ToString()
            message = $this.Message
            context = $this.Context
            metrics = $this.Metrics
        } | ConvertTo-Json -Compress
    }
}

# Main orchestration
class BushidoProjectOrchestrator {
    hidden [ReactiveLogger]$Logger
    hidden [BushidoProjectConfiguration]$Config
    hidden [ProjectBuilder]$Builder
    
    BushidoProjectOrchestrator() {
        $this.Config = [BushidoProjectConfiguration]::new()
        $logPath = Join-Path $this.Config.ProjectRoot "logs/setup.log"
        $this.Logger = [ReactiveLogger]::new($logPath)
        $this.Builder = [ProjectBuilder]::new($this.Logger, $this.Config)
    }
    
    [void] Execute() {
        try {
            $this.ShowBanner()
            
            $this.Logger.Log("Initializing Bushido NFT project", [LogLevel]::Info)
            
            # Build the project with fluent pattern
            $this.Builder
                .CreateWorkspaceStructure()
                .CreateContractsPackage()
                .CreateFrontendPackage()
            
            # Install dependencies
            $this.Logger.Log("Installing dependencies (this may take a few minutes)", [LogLevel]::Info)
            pnpm install
            
            $this.ShowSuccess()
        }
        catch {
            $this.Logger.Log("Project setup failed: $_", [LogLevel]::Critical)
            $this.ShowFailure()
            throw
        }
        finally {
            $this.Logger.Dispose()
        }
    }
    
    hidden [void] ShowBanner() {
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
        
        Write-Host "    Stealth Launch Edition | Abstract L2 Ready" -ForegroundColor DarkGray
        Write-Host "    ═══════════════════════════════════════════════════`n" -ForegroundColor DarkRed
    }
    
    hidden [void] ShowSuccess() {
        Write-Host "`n    ✨ " -NoNewline -ForegroundColor Magenta
        Write-Host "PROJECT GENESIS COMPLETE!" -ForegroundColor White
        Write-Host "    ═══════════════════════════════════════════════════" -ForegroundColor DarkGreen
        
        Write-Host "`n    🚀 Quick Start Commands:" -ForegroundColor Cyan
        Write-Host "       pnpm dev              " -NoNewline -ForegroundColor White
        Write-Host "# Start all services" -ForegroundColor DarkGray
        Write-Host "       pnpm build            " -NoNewline -ForegroundColor White
        Write-Host "# Build for production" -ForegroundColor DarkGray
        Write-Host "       pnpm test             " -NoNewline -ForegroundColor White
        Write-Host "# Run test suites" -ForegroundColor DarkGray
        
        Write-Host "`n    📁 Project Structure:" -ForegroundColor Yellow
        Write-Host "       /contracts            " -NoNewline -ForegroundColor White
        Write-Host "# Smart contracts (Hardhat)" -ForegroundColor DarkGray
        Write-Host "       /frontend             " -NoNewline -ForegroundColor White
        Write-Host "# Next.js 14 app" -ForegroundColor DarkGray
        Write-Host "       /backend              " -NoNewline -ForegroundColor White
        Write-Host "# Express API server" -ForegroundColor DarkGray
        Write-Host "       /scripts              " -NoNewline -ForegroundColor White
        Write-Host "# Deployment tools" -ForegroundColor DarkGray
        
        Write-Host "`n    ⚡ Next Steps:" -ForegroundColor Magenta
        Write-Host "       1. Configure .env file with your keys" -ForegroundColor White
        Write-Host "       2. Deploy contracts: " -NoNewline -ForegroundColor White
        Write-Host "pnpm deploy:testnet" -ForegroundColor Yellow
        Write-Host "       3. Start development: " -NoNewline -ForegroundColor White
        Write-Host "pnpm dev`n" -ForegroundColor Yellow
    }
    
    hidden [void] ShowFailure() {
        Write-Host "`n    ❌ Setup failed - check logs for details" -ForegroundColor Red
        Write-Host "    Log location: $(Join-Path $this.Config.ProjectRoot 'logs/setup.log')`n" -ForegroundColor Gray
    }
}

# Execute the orchestrator
$orchestrator = [BushidoProjectOrchestrator]::new()
$orchestrator.Execute()