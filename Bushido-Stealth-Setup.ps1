# Bushido-Stealth-Setup.ps1
# An architectural masterpiece for Bushido NFT stealth launch orchestration
# Demonstrates advanced PowerShell patterns with functional composition

#Requires -Version 7.0
using namespace System.Collections.Generic
using namespace System.Collections.Concurrent
using namespace System.IO
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
    [switch]$StealthMode = $true,
    
    [Parameter()]
    [ValidateSet('Silent', 'Normal', 'Verbose', 'Diagnostic')]
    [string]$LogLevel = 'Normal'
)

# ═══════════════════════════════════════════════════════════════════
# Functional Composition Architecture
# ═══════════════════════════════════════════════════════════════════

# Monadic Result type for elegant error handling
class Result {
    [bool]$Success
    [object]$Value
    [string]$Error
    
    static [Result] Ok([object]$value) {
        return [Result]@{ Success = $true; Value = $value; Error = $null }
    }
    
    static [Result] Fail([string]$error) {
        return [Result]@{ Success = $false; Value = $null; Error = $error }
    }
    
    [Result] Map([ScriptBlock]$transform) {
        if ($this.Success) {
            try {
                $newValue = & $transform $this.Value
                return [Result]::Ok($newValue)
            }
            catch {
                return [Result]::Fail($_.Exception.Message)
            }
        }
        return $this
    }
    
    [Result] FlatMap([ScriptBlock]$transform) {
        if ($this.Success) {
            try {
                return & $transform $this.Value
            }
            catch {
                return [Result]::Fail($_.Exception.Message)
            }
        }
        return $this
    }
    
    [object] GetOrElse([object]$default) {
        return $this.Success ? $this.Value : $default
    }
}

# ═══════════════════════════════════════════════════════════════════
# Configuration as Code - Immutable Domain Model
# ═══════════════════════════════════════════════════════════════════

class BushidoClan {
    [int]$Id
    [string]$Name
    [string]$Virtue
    [string]$Symbol
    [string]$Color
    
    BushidoClan([int]$id, [string]$name, [string]$virtue, [string]$symbol, [string]$color) {
        $this.Id = $id
        $this.Name = $name
        $this.Virtue = $virtue
        $this.Symbol = $symbol
        $this.Color = $color
    }
}

class BushidoConfiguration {
    [string]$ProjectName = "bushido-nft"
    [int]$TotalSupply = 1600
    [int]$ClansCount = 8
    [int]$TokensPerClan = 200
    [decimal]$MintPrice = 0.08
    [int]$MaxPerWallet = 3
    [string]$Blockchain = "Abstract L2"
    
    [BushidoClan[]]$Clans = @(
        [BushidoClan]::new(0, "Dragon", "Courage", "🐉", "#DC2626")
        [BushidoClan]::new(1, "Phoenix", "Rebirth", "🔥", "#F59E0B")
        [BushidoClan]::new(2, "Tiger", "Strength", "🐅", "#F97316")
        [BushidoClan]::new(3, "Serpent", "Wisdom", "🐍", "#8B5CF6")
        [BushidoClan]::new(4, "Eagle", "Vision", "🦅", "#3B82F6")
        [BushidoClan]::new(5, "Wolf", "Loyalty", "🐺", "#6B7280")
        [BushidoClan]::new(6, "Bear", "Protection", "🐻", "#92400E")
        [BushidoClan]::new(7, "Lion", "Leadership", "🦁", "#EAB308")
    )
    
    [hashtable]$RequiredTools = @{
        node = @{ MinVersion = [Version]"18.0.0"; Command = "node --version"; Pattern = "v?(\d+\.\d+\.\d+)" }
        pnpm = @{ MinVersion = [Version]"8.0.0"; Command = "pnpm --version"; Pattern = "(\d+\.\d+\.\d+)" }
        git = @{ MinVersion = [Version]"2.0.0"; Command = "git --version"; Pattern = "(\d+\.\d+\.\d+)" }
    }
    
    [hashtable] GetRarityDistribution() {
        return @{
            Legendary = @{ Percentage = 1; Power = 25; Count = 16 }
            Epic = @{ Percentage = 4; Power = 16; Count = 64 }
            Rare = @{ Percentage = 10; Power = 9; Count = 160 }
            Uncommon = @{ Percentage = 20; Power = 4; Count = 320 }
            Common = @{ Percentage = 65; Power = 1; Count = 1040 }
        }
    }
}

# ═══════════════════════════════════════════════════════════════════
# Advanced Logging System with Observer Pattern
# ═══════════════════════════════════════════════════════════════════

enum LogLevel {
    Silent = 0
    Normal = 1
    Verbose = 2
    Diagnostic = 3
}

interface ILogObserver {
    [void] OnLogEvent([LogEvent]$event)
}

class LogEvent {
    [DateTime]$Timestamp
    [string]$Level
    [string]$Message
    [hashtable]$Context
    [string]$Source
    
    LogEvent([string]$level, [string]$message, [hashtable]$context = @{}) {
        $this.Timestamp = [DateTime]::UtcNow
        $this.Level = $level
        $this.Message = $message
        $this.Context = $context
        $this.Source = (Get-PSCallStack)[2].Command
    }
}

class ConsoleLogObserver : ILogObserver {
    [LogLevel]$MinLevel
    
    ConsoleLogObserver([LogLevel]$minLevel) {
        $this.MinLevel = $minLevel
    }
    
    [void] OnLogEvent([LogEvent]$event) {
        if ($this.ShouldLog($event)) {
            $this.WriteFormattedLog($event)
        }
    }
    
    hidden [bool] ShouldLog([LogEvent]$event) {
        $eventLevel = switch ($event.Level) {
            "Error" { [LogLevel]::Silent }
            "Warning" { [LogLevel]::Normal }
            "Success" { [LogLevel]::Normal }
            "Info" { [LogLevel]::Normal }
            "Verbose" { [LogLevel]::Verbose }
            "Debug" { [LogLevel]::Diagnostic }
            default { [LogLevel]::Normal }
        }
        return $eventLevel -le $this.MinLevel
    }
    
    hidden [void] WriteFormattedLog([LogEvent]$event) {
        $colors = @{
            "Error" = "Red"
            "Warning" = "Yellow"
            "Success" = "Green"
            "Info" = "Cyan"
            "Verbose" = "Blue"
            "Debug" = "DarkGray"
            "Stealth" = "Magenta"
        }
        
        $symbols = @{
            "Error" = "❌"
            "Warning" = "⚠️"
            "Success" = "✅"
            "Info" = "ℹ️"
            "Verbose" = "📝"
            "Debug" = "🔍"
            "Stealth" = "🥷"
        }
        
        $timestamp = $event.Timestamp.ToLocalTime().ToString("HH:mm:ss")
        $color = $colors[$event.Level] ?? "White"
        $symbol = $symbols[$event.Level] ?? "•"
        
        Write-Host "[$timestamp] " -NoNewline -ForegroundColor DarkGray
        Write-Host "$symbol " -NoNewline
        Write-Host $event.Message -ForegroundColor $color
        
        if ($this.MinLevel -ge [LogLevel]::Verbose -and $event.Context.Count -gt 0) {
            Write-Host "    Context: " -NoNewline -ForegroundColor DarkGray
            Write-Host ($event.Context | ConvertTo-Json -Compress) -ForegroundColor DarkGray
        }
    }
}

class FileLogObserver : ILogObserver {
    [string]$LogPath
    [ConcurrentQueue[LogEvent]]$Queue
    [System.Threading.Timer]$FlushTimer
    
    FileLogObserver([string]$logPath) {
        $this.LogPath = $logPath
        $this.Queue = [ConcurrentQueue[LogEvent]]::new()
        $this.EnsureLogDirectory()
        $this.InitializeFlushTimer()
    }
    
    hidden [void] EnsureLogDirectory() {
        $dir = Split-Path $this.LogPath -Parent
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    hidden [void] InitializeFlushTimer() {
        $callback = [System.Threading.TimerCallback]{
            param($state)
            $observer = [FileLogObserver]$state
            $observer.Flush()
        }
        
        $this.FlushTimer = [System.Threading.Timer]::new(
            $callback,
            $this,
            [TimeSpan]::FromSeconds(5),
            [TimeSpan]::FromSeconds(5)
        )
    }
    
    [void] OnLogEvent([LogEvent]$event) {
        $this.Queue.Enqueue($event)
    }
    
    [void] Flush() {
        $events = [List[LogEvent]]::new()
        $event = $null
        
        while ($this.Queue.TryDequeue([ref]$event)) {
            $events.Add($event)
        }
        
        if ($events.Count -gt 0) {
            $logEntries = $events | ForEach-Object {
                @{
                    Timestamp = $_.Timestamp.ToString("o")
                    Level = $_.Level
                    Message = $_.Message
                    Context = $_.Context
                    Source = $_.Source
                }
            }
            
            $json = $logEntries | ConvertTo-Json -Depth 10
            Add-Content -Path $this.LogPath -Value $json -Encoding UTF8
        }
    }
    
    [void] Dispose() {
        $this.FlushTimer?.Dispose()
        $this.Flush()
    }
}

class BushidoLogger {
    [List[ILogObserver]]$Observers
    [ConcurrentDictionary[string, int]]$Metrics
    
    BushidoLogger() {
        $this.Observers = [List[ILogObserver]]::new()
        $this.Metrics = [ConcurrentDictionary[string, int]]::new()
    }
    
    [void] AddObserver([ILogObserver]$observer) {
        $this.Observers.Add($observer)
    }
    
    [void] Log([string]$message, [string]$level = "Info", [hashtable]$context = @{}) {
        $event = [LogEvent]::new($level, $message, $context)
        
        # Update metrics
        $metricKey = "Level_$level"
        [void]$this.Metrics.AddOrUpdate($metricKey, 1, { param($key, $value) $value + 1 })
        
        # Notify observers
        foreach ($observer in $this.Observers) {
            try {
                $observer.OnLogEvent($event)
            }
            catch {
                # Prevent observer errors from breaking logging
            }
        }
    }
    
    [hashtable] GetMetrics() {
        $result = @{}
        foreach ($kvp in $this.Metrics.GetEnumerator()) {
            $result[$kvp.Key] = $kvp.Value
        }
        return $result
    }
}

# ═══════════════════════════════════════════════════════════════════
# Builder Pattern with Fluent Interface
# ═══════════════════════════════════════════════════════════════════

class ProjectFileBuilder {
    hidden [string]$Path
    hidden [string]$Content
    hidden [string]$Encoding = "UTF8"
    
    ProjectFileBuilder([string]$path) {
        $this.Path = $path
    }
    
    [ProjectFileBuilder] WithContent([string]$content) {
        $this.Content = $content
        return $this
    }
    
    [ProjectFileBuilder] WithJsonContent([object]$obj) {
        $this.Content = $obj | ConvertTo-Json -Depth 10 -Compress:$false
        return $this
    }
    
    [ProjectFileBuilder] WithEncoding([string]$encoding) {
        $this.Encoding = $encoding
        return $this
    }
    
    [Result] Build() {
        try {
            $dir = Split-Path $this.Path -Parent
            if ($dir -and -not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            
            # Atomic write
            $tempPath = "$($this.Path).tmp"
            Set-Content -Path $tempPath -Value $this.Content -Encoding $this.Encoding -NoNewline
            Move-Item -Path $tempPath -Destination $this.Path -Force
            
            return [Result]::Ok($this.Path)
        }
        catch {
            return [Result]::Fail("Failed to create file $($this.Path): $_")
        }
    }
}

# ═══════════════════════════════════════════════════════════════════
# Command Pattern for Reversible Operations
# ═══════════════════════════════════════════════════════════════════

interface ICommand {
    [Result] Execute()
    [void] Undo()
}

class CreateDirectoryCommand : ICommand {
    [string]$Path
    
    CreateDirectoryCommand([string]$path) {
        $this.Path = $path
    }
    
    [Result] Execute() {
        try {
            if (-not (Test-Path $this.Path)) {
                New-Item -ItemType Directory -Path $this.Path -Force | Out-Null
            }
            return [Result]::Ok($this.Path)
        }
        catch {
            return [Result]::Fail("Failed to create directory: $_")
        }
    }
    
    [void] Undo() {
        if (Test-Path $this.Path) {
            Remove-Item $this.Path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

class CommandExecutor {
    [Stack[ICommand]]$ExecutedCommands
    [BushidoLogger]$Logger
    
    CommandExecutor([BushidoLogger]$logger) {
        $this.ExecutedCommands = [Stack[ICommand]]::new()
        $this.Logger = $logger
    }
    
    [Result] Execute([ICommand]$command) {
        $result = $command.Execute()
        
        if ($result.Success) {
            $this.ExecutedCommands.Push($command)
            $this.Logger.Log("Command executed successfully", "Verbose", @{
                Command = $command.GetType().Name
                Details = $result.Value
            })
        }
        else {
            $this.Logger.Log("Command failed", "Error", @{
                Command = $command.GetType().Name
                Error = $result.Error
            })
        }
        
        return $result
    }
    
    [void] UndoAll() {
        $this.Logger.Log("Initiating rollback", "Warning")
        
        while ($this.ExecutedCommands.Count -gt 0) {
            $command = $this.ExecutedCommands.Pop()
            try {
                $command.Undo()
                $this.Logger.Log("Rolled back command", "Verbose", @{
                    Command = $command.GetType().Name
                })
            }
            catch {
                $this.Logger.Log("Rollback failed", "Error", @{
                    Command = $command.GetType().Name
                    Error = $_.Exception.Message
                })
            }
        }
    }
}

# ═══════════════════════════════════════════════════════════════════
# Project Structure Builders with Template Method Pattern
# ═══════════════════════════════════════════════════════════════════

abstract class PackageBuilder {
    [string]$Path
    [BushidoConfiguration]$Config
    [CommandExecutor]$Executor
    
    PackageBuilder([string]$path, [BushidoConfiguration]$config, [CommandExecutor]$executor) {
        $this.Path = $path
        $this.Config = $config
        $this.Executor = $executor
    }
    
    [Result] Build() {
        return $this.CreateDirectory()
            .FlatMap({ $this.CreatePackageJson() })
            .FlatMap({ $this.CreateStructure() })
            .FlatMap({ $this.CreateSourceFiles() })
    }
    
    hidden [Result] CreateDirectory() {
        return $this.Executor.Execute([CreateDirectoryCommand]::new($this.Path))
    }
    
    abstract [Result] CreatePackageJson()
    abstract [Result] CreateStructure()
    abstract [Result] CreateSourceFiles()
}

class ContractsPackageBuilder : PackageBuilder {
    ContractsPackageBuilder([string]$basePath, [BushidoConfiguration]$config, [CommandExecutor]$executor) 
        : base((Join-Path $basePath "contracts"), $config, $executor) {}
    
    [Result] CreatePackageJson() {
        $package = @{
            name = "@bushido/contracts"
            version = "1.0.0"
            private = $true
            scripts = @{
                "compile" = "hardhat compile"
                "test" = "hardhat test"
                "test:coverage" = "hardhat coverage"
                "deploy" = "hardhat run scripts/deploy.ts"
                "verify" = "hardhat verify"
                "size" = "hardhat size-contracts"
            }
            devDependencies = @{
                "hardhat" = "^2.19.4"
                "@nomicfoundation/hardhat-toolbox" = "^4.0.0"
                "@openzeppelin/contracts" = "^5.0.1"
                "hardhat-contract-sizer" = "^2.10.0"
            }
        }
        
        return [ProjectFileBuilder]::new((Join-Path $this.Path "package.json"))
            .WithJsonContent($package)
            .Build()
    }
    
    [Result] CreateStructure() {
        $dirs = @("contracts", "contracts/interfaces", "contracts/libraries", "scripts", "test")
        
        foreach ($dir in $dirs) {
            $result = $this.Executor.Execute(
                [CreateDirectoryCommand]::new((Join-Path $this.Path $dir))
            )
            if (-not $result.Success) { return $result }
        }
        
        return [Result]::Ok($null)
    }
    
    [Result] CreateSourceFiles() {
        # Main contract
        $contractResult = $this.CreateMainContract()
        if (-not $contractResult.Success) { return $contractResult }
        
        # Interface
        $interfaceResult = $this.CreateInterface()
        if (-not $interfaceResult.Success) { return $interfaceResult }
        
        # Library
        $libraryResult = $this.CreateVotingLibrary()
        if (-not $libraryResult.Success) { return $libraryResult }
        
        # Hardhat config
        return $this.CreateHardhatConfig()
    }
    
    hidden [Result] CreateMainContract() {
        $contract = @'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IBushidoNFT.sol";
import "./libraries/VotingPower.sol";

/**
 * @title BushidoNFT
 * @author Bushido Development Team
 * @notice Interactive NFT with integrated voting for episodic storytelling
 * @dev Implements gas-efficient voting system optimized for Abstract L2
 */
contract BushidoNFT is ERC721Enumerable, Ownable, ReentrancyGuard, IBushidoNFT {
    using Counters for Counters.Counter;
    using VotingPower for uint256;
    
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
    
    function castVote(uint256 tokenId, uint8 choice) external override {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(!hasVoted[tokenId][currentEpisode], "Already voted");
        require(choice > 0 && choice <= 4, "Invalid choice");
        
        hasVoted[tokenId][currentEpisode] = true;
        uint256 power = tokenRarity[tokenId].calculateVotingPower();
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
        require(success, "Transfer failed");
    }
}
'@
        
        return [ProjectFileBuilder]::new((Join-Path $this.Path "contracts/BushidoNFT.sol"))
            .WithContent($contract)
            .Build()
    }
    
    hidden [Result] CreateInterface() {
        $interface = @'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBushidoNFT {
    function castVote(uint256 tokenId, uint8 choice) external;
}
'@
        
        return [ProjectFileBuilder]::new((Join-Path $this.Path "contracts/interfaces/IBushidoNFT.sol"))
            .WithContent($interface)
            .Build()
    }
    
    hidden [Result] CreateVotingLibrary() {
        $library = @'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library VotingPower {
    function calculateVotingPower(uint256 rarity) internal pure returns (uint256) {
        return rarity * rarity;
    }
}
'@
        
        return [ProjectFileBuilder]::new((Join-Path $this.Path "contracts/libraries/VotingPower.sol"))
            .WithContent($library)
            .Build()
    }
    
    hidden [Result] CreateHardhatConfig() {
        $config = @'
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-contract-sizer";
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
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true
  }
};

export default config;
'@
        
        return [ProjectFileBuilder]::new((Join-Path $this.Path "hardhat.config.ts"))
            .WithContent($config)
            .Build()
    }
}

# ═══════════════════════════════════════════════════════════════════
# Main Project Orchestrator
# ═══════════════════════════════════════════════════════════════════

class BushidoProjectOrchestrator {
    [BushidoConfiguration]$Config
    [BushidoLogger]$Logger
    [CommandExecutor]$Executor
    [string]$ProjectPath
    
    BushidoProjectOrchestrator([string]$projectPath, [string]$logLevel) {
        $this.ProjectPath = $projectPath
        $this.Config = [BushidoConfiguration]::new()
        $this.Logger = [BushidoLogger]::new()
        $this.Executor = [CommandExecutor]::new($this.Logger)
        
        $this.InitializeLogging($logLevel)
    }
    
    hidden [void] InitializeLogging([string]$logLevel) {
        # Console logger
        $level = [LogLevel]::$logLevel
        $this.Logger.AddObserver([ConsoleLogObserver]::new($level))
        
        # File logger
        $logPath = Join-Path $this.ProjectPath "logs" "bushido-setup.log"
        $fileObserver = [FileLogObserver]::new($logPath)
        $this.Logger.AddObserver($fileObserver)
    }
    
    [Result] ValidatePrerequisites() {
        $this.Logger.Log("Validating prerequisites", "Info")
        
        foreach ($tool in $this.Config.RequiredTools.GetEnumerator()) {
            try {
                $output = Invoke-Expression $tool.Value.Command 2>&1 | Out-String
                
                if ($output -match $tool.Value.Pattern) {
                    $version = [Version]$Matches[1]
                    
                    if ($version -ge $tool.Value.MinVersion) {
                        $this.Logger.Log("$($tool.Key) validated", "Success", @{
                            Tool = $tool.Key
                            Version = $version.ToString()
                            Required = $tool.Value.MinVersion.ToString()
                        })
                    }
                    else {
                        return [Result]::Fail("$($tool.Key) version $version is below minimum required version $($tool.Value.MinVersion)")
                    }
                }
                else {
                    return [Result]::Fail("Could not parse version for $($tool.Key)")
                }
            }
            catch {
                return [Result]::Fail("$($tool.Key) not found. Please install it first.")
            }
        }
        
        return [Result]::Ok($null)
    }
    
    [Result] CreateRootStructure() {
        $this.Logger.Log("Creating root project structure", "Info")
        
        # Root package.json
        $rootPackage = @{
            name = $this.Config.ProjectName
            version = "1.0.0"
            private = $true
            type = "module"
            scripts = @{
                "dev" = "turbo run dev --parallel"
                "build" = "turbo run build"
                "test" = "turbo run test"
                "deploy:testnet" = "turbo run deploy --filter=@bushido/contracts -- --network abstractTestnet"
                "deploy:mainnet" = "turbo run deploy --filter=@bushido/contracts -- --network abstract"
                "launch:countdown" = "pnpm run build && vercel --prod"
            }
            devDependencies = @{
                "turbo" = "latest"
                "prettier" = "^3.2.5"
                "vercel" = "^32.7.2"
            }
        }
        
        $packageResult = [ProjectFileBuilder]::new("package.json")
            .WithJsonContent($rootPackage)
            .Build()
            
        if (-not $packageResult.Success) { return $packageResult }
        
        # pnpm workspace
        $workspace = @"
packages:
  - 'contracts'
  - 'frontend'
  - 'backend'
  - 'scripts'
  - 'episodes'
"@
        
        $workspaceResult = [ProjectFileBuilder]::new("pnpm-workspace.yaml")
            .WithContent($workspace)
            .Build()
            
        if (-not $workspaceResult.Success) { return $workspaceResult }
        
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
                    dependsOn = @("build")
                    outputs = @("coverage/**")
                }
                deploy = @{
                    dependsOn = @("build", "test")
                    cache = $false
                }
            }
        }
        
        return [ProjectFileBuilder]::new("turbo.json")
            .WithJsonContent($turbo)
            .Build()
    }
    
    [Result] CreatePackages() {
        $this.Logger.Log("Creating package structures", "Info")
        
        # Contracts
        $contractsBuilder = [ContractsPackageBuilder]::new($this.ProjectPath, $this.Config, $this.Executor)
        $contractsResult = $contractsBuilder.Build()
        if (-not $contractsResult.Success) { return $contractsResult }
        
        # Frontend (minimal for now)
        $frontendResult = $this.CreateMinimalPackage("frontend", @{
            name = "@bushido/frontend"
            scripts = @{
                "dev" = "next dev"
                "build" = "next build"
            }
        })
        if (-not $frontendResult.Success) { return $frontendResult }
        
        # Backend
        $backendResult = $this.CreateMinimalPackage("backend", @{
            name = "@bushido/backend"
            scripts = @{
                "dev" = "nodemon src/index.ts"
                "build" = "tsc"
            }
        })
        if (-not $backendResult.Success) { return $backendResult }
        
        # Scripts
        $scriptsResult = $this.CreateMinimalPackage("scripts", @{
            name = "@bushido/scripts"
            scripts = @{
                "generate-metadata" = "ts-node src/generate-metadata.ts"
            }
        })
        if (-not $scriptsResult.Success) { return $scriptsResult }
        
        # Episodes
        return $this.CreateMinimalPackage("episodes", @{
            name = "@bushido/episodes"
            private = $true
        })
    }
    
    hidden [Result] CreateMinimalPackage([string]$name, [hashtable]$packageJson) {
        $path = Join-Path $this.ProjectPath $name
        
        $dirResult = $this.Executor.Execute([CreateDirectoryCommand]::new($path))
        if (-not $dirResult.Success) { return $dirResult }
        
        $defaultPackage = @{
            version = "1.0.0"
            private = $true
        }
        
        foreach ($key in $packageJson.Keys) {
            $defaultPackage[$key] = $packageJson[$key]
        }
        
        return [ProjectFileBuilder]::new((Join-Path $path "package.json"))
            .WithJsonContent($defaultPackage)
            .Build()
    }
    
    [Result] CreateConfigurationFiles() {
        $this.Logger.Log("Creating configuration files", "Info")
        
        # .gitignore
        $gitignore = @"
# Dependencies
node_modules/
.pnpm-store/

# Build outputs
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
        
        $gitignoreResult = [ProjectFileBuilder]::new(".gitignore")
            .WithContent($gitignore)
            .Build()
            
        if (-not $gitignoreResult.Success) { return $gitignoreResult }
        
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
        
        return [ProjectFileBuilder]::new(".env.example")
            .WithContent($env)
            .Build()
    }
    
    [Result] Execute() {
        try {
            # Create project directory if needed
            if ($this.ProjectPath -ne (Get-Location).Path) {
                $dirResult = $this.Executor.Execute(
                    [CreateDirectoryCommand]::new($this.ProjectPath)
                )
                if (-not $dirResult.Success) { return $dirResult }
                
                Set-Location $this.ProjectPath
            }
            
            # Execute setup steps
            return $this.CreateRootStructure()
                .FlatMap({ $this.CreatePackages() })
                .FlatMap({ $this.CreateConfigurationFiles() })
                .Map({ 
                    $metrics = $this.Logger.GetMetrics()
                    @{
                        Success = $true
                        Metrics = $metrics
                        Message = "Project setup completed successfully"
                    }
                })
        }
        catch {
            $this.Logger.Log("Fatal error during setup", "Error", @{
                Error = $_.Exception.Message
                StackTrace = $_.ScriptStackTrace
            })
            
            $this.Executor.UndoAll()
            
            return [Result]::Fail($_.Exception.Message)
        }
    }
    
    [void] Dispose() {
        foreach ($observer in $this.Logger.Observers) {
            if ($observer -is [IDisposable]) {
                $observer.Dispose()
            }
        }
    }
}

# ═══════════════════════════════════════════════════════════════════
# Entry Point with Beautiful CLI
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
    param([BushidoConfiguration]$config)
    
    Write-Host "    📋 Project Configuration:" -ForegroundColor Yellow
    Write-Host "       NFT Supply:     " -NoNewline -ForegroundColor White
    Write-Host "$($config.TotalSupply) ($($config.ClansCount) clans × $($config.TokensPerClan) tokens)" -ForegroundColor DarkGray
    Write-Host "       Mint Price:     " -NoNewline -ForegroundColor White
    Write-Host "$($config.MintPrice) ETH" -ForegroundColor DarkGray
    Write-Host "       Blockchain:     " -NoNewline -ForegroundColor White
    Write-Host $config.Blockchain -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "    🏯 The Eight Clans:" -ForegroundColor Cyan
    foreach ($clan in $config.Clans) {
        Write-Host "       $($clan.Symbol) " -NoNewline
        Write-Host "$($clan.Name.PadRight(10))" -NoNewline -ForegroundColor White
        Write-Host "- $($clan.Virtue)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Show-Results {
    param([hashtable]$results)
    
    Write-Host "`n    ✨ " -NoNewline -ForegroundColor Magenta
    Write-Host "SETUP COMPLETE!" -ForegroundColor White
    Write-Host "    ═══════════════════════════════════════════════════" -ForegroundColor DarkGreen
    
    if ($results.Metrics) {
        Write-Host "`n    📊 Execution Metrics:" -ForegroundColor Yellow
        foreach ($metric in $results.Metrics.GetEnumerator()) {
            $label = $metric.Key -replace 'Level_', ''
            Write-Host "       $($label.PadRight(12))" -NoNewline -ForegroundColor White
            Write-Host $metric.Value -ForegroundColor Green
        }
    }
    
    Write-Host "`n    🚀 Next Steps:" -ForegroundColor Cyan
    Write-Host "       1. Install dependencies:    " -NoNewline -ForegroundColor White
    Write-Host "pnpm install" -ForegroundColor Yellow
    Write-Host "       2. Configure environment:   " -NoNewline -ForegroundColor White
    Write-Host "cp .env.example .env" -ForegroundColor Yellow
    Write-Host "       3. Deploy contracts:        " -NoNewline -ForegroundColor White
    Write-Host "pnpm deploy:testnet" -ForegroundColor Yellow
    Write-Host "       4. Launch countdown:        " -NoNewline -ForegroundColor White
    Write-Host "pnpm launch:countdown" -ForegroundColor Yellow
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════
# Main Execution
# ═══════════════════════════════════════════════════════════════════

$orchestrator = $null

try {
    Show-Banner
    
    $config = [BushidoConfiguration]::new()
    Show-Configuration -config $config
    
    # Initialize orchestrator
    $orchestrator = [BushidoProjectOrchestrator]::new($ProjectPath, $LogLevel)
    
    # Validate prerequisites
    if (-not $SkipPrerequisites) {
        $prereqResult = $orchestrator.ValidatePrerequisites()
        if (-not $prereqResult.Success) {
            Write-Host "`n    ❌ Prerequisites check failed" -ForegroundColor Red
            Write-Host "       $($prereqResult.Error)" -ForegroundColor Yellow
            exit 1
        }
    }
    
    # Execute setup
    Write-Host "    🔨 Initializing project structure..." -ForegroundColor Cyan
    $result = $orchestrator.Execute()
    
    if ($result.Success) {
        Show-Results -results $result.Value
    }
    else {
        Write-Host "`n    ❌ Setup failed" -ForegroundColor Red
        Write-Host "       $($result.Error)" -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Host "`n    💥 Fatal Error" -ForegroundColor Red
    Write-Host "       $_" -ForegroundColor Yellow
    Write-Host "`n$($_.ScriptStackTrace)" -ForegroundColor DarkGray
    exit 1
}
finally {
    $orchestrator?.Dispose()
}