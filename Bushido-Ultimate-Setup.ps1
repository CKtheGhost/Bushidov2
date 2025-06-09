# Bushido-Ultimate-Setup.ps1
# A masterclass in PowerShell architecture for Bushido NFT project initialization
# Demonstrates advanced patterns using PowerShell's actual capabilities

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
    [ValidateSet('Quiet', 'Normal', 'Detailed', 'Diagnostic')]
    [string]$OutputLevel = 'Normal'
)

# ═══════════════════════════════════════════════════════════════════
# Advanced Configuration System with Immutable Domain Objects
# ═══════════════════════════════════════════════════════════════════

class BushidoConfig {
    static [hashtable]$Project = @{
        Name = "bushido-nft"
        TotalSupply = 1600
        ClansCount = 8
        TokensPerClan = 200
        MintPrice = 0.08
        MaxPerWallet = 3
        Blockchain = "Abstract L2"
    }
    
    static [array]$Clans = @(
        @{ Id = 0; Name = "Dragon"; Virtue = "Courage"; Symbol = "🐉"; Color = "#DC2626" }
        @{ Id = 1; Name = "Phoenix"; Virtue = "Rebirth"; Symbol = "🔥"; Color = "#F59E0B" }
        @{ Id = 2; Name = "Tiger"; Virtue = "Strength"; Symbol = "🐅"; Color = "#F97316" }
        @{ Id = 3; Name = "Serpent"; Virtue = "Wisdom"; Symbol = "🐍"; Color = "#8B5CF6" }
        @{ Id = 4; Name = "Eagle"; Virtue = "Vision"; Symbol = "🦅"; Color = "#3B82F6" }
        @{ Id = 5; Name = "Wolf"; Virtue = "Loyalty"; Symbol = "🐺"; Color = "#6B7280" }
        @{ Id = 6; Name = "Bear"; Virtue = "Protection"; Symbol = "🐻"; Color = "#92400E" }
        @{ Id = 7; Name = "Lion"; Virtue = "Leadership"; Symbol = "🦁"; Color = "#EAB308" }
    )
    
    static [hashtable]$Prerequisites = @{
        node = @{ 
            MinVersion = [Version]"18.0.0"
            Command = { node --version }
            Pattern = "v?(\d+\.\d+\.\d+)"
            ErrorMsg = "Node.js 18+ required. Install from: https://nodejs.org"
        }
        pnpm = @{ 
            MinVersion = [Version]"8.0.0"
            Command = { pnpm --version }
            Pattern = "(\d+\.\d+\.\d+)"
            ErrorMsg = "pnpm 8+ required. Install: npm install -g pnpm"
        }
        git = @{ 
            MinVersion = [Version]"2.0.0"
            Command = { git --version }
            Pattern = "git version (\d+\.\d+\.\d+)"
            ErrorMsg = "Git required. Install from: https://git-scm.com"
        }
    }
    
    static [hashtable]$RarityTiers = @{
        Common = @{ Id = 1; Percentage = 65; Power = 1; Color = "#6B7280" }
        Uncommon = @{ Id = 2; Percentage = 20; Power = 4; Color = "#10B981" }
        Rare = @{ Id = 3; Percentage = 10; Power = 9; Color = "#3B82F6" }
        Epic = @{ Id = 4; Percentage = 4; Power = 16; Color = "#8B5CF6" }
        Legendary = @{ Id = 5; Percentage = 1; Power = 25; Color = "#F59E0B" }
    }
}

# ═══════════════════════════════════════════════════════════════════
# Result Monad for Elegant Error Handling
# ═══════════════════════════════════════════════════════════════════

class Result {
    [bool]$Success
    [object]$Value
    [string]$Error
    hidden [System.Collections.ArrayList]$Warnings = @()
    
    hidden Result([bool]$success, [object]$value, [string]$error) {
        $this.Success = $success
        $this.Value = $value
        $this.Error = $error
    }
    
    static [Result] Ok([object]$value) {
        return [Result]::new($true, $value, $null)
    }
    
    static [Result] Fail([string]$error) {
        return [Result]::new($false, $null, $error)
    }
    
    [Result] Map([scriptblock]$transform) {
        if (-not $this.Success) { return $this }
        
        try {
            $newValue = & $transform $this.Value
            $result = [Result]::Ok($newValue)
            $result.Warnings.AddRange($this.Warnings)
            return $result
        }
        catch {
            return [Result]::Fail("Transform failed: $_")
        }
    }
    
    [Result] Then([scriptblock]$operation) {
        if (-not $this.Success) { return $this }
        
        try {
            $result = & $operation $this.Value
            if ($result -is [Result]) {
                $result.Warnings.AddRange($this.Warnings)
                return $result
            }
            return [Result]::Ok($result)
        }
        catch {
            return [Result]::Fail("Operation failed: $_")
        }
    }
    
    [Result] Catch([scriptblock]$handler) {
        if ($this.Success) { return $this }
        
        try {
            return & $handler $this.Error
        }
        catch {
            return [Result]::Fail("Error handler failed: $_")
        }
    }
    
    [void] AddWarning([string]$warning) {
        $this.Warnings.Add($warning) | Out-Null
    }
    
    [object] Unwrap() {
        if (-not $this.Success) {
            throw "Cannot unwrap failed result: $($this.Error)"
        }
        return $this.Value
    }
    
    [object] UnwrapOr([object]$default) {
        return $this.Success ? $this.Value : $default
    }
}

# ═══════════════════════════════════════════════════════════════════
# Advanced Logging System with Strategy Pattern
# ═══════════════════════════════════════════════════════════════════

class LogEntry {
    [DateTime]$Timestamp = [DateTime]::UtcNow
    [string]$Level
    [string]$Message
    [hashtable]$Context
    [string]$Source
    
    LogEntry([string]$level, [string]$message, [hashtable]$context) {
        $this.Level = $level
        $this.Message = $message
        $this.Context = $context
        
        # Capture calling context
        $callStack = Get-PSCallStack
        if ($callStack.Count -gt 2) {
            $this.Source = $callStack[2].Command
        }
    }
}

class LogFormatter {
    static [string] FormatConsole([LogEntry]$entry) {
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
        
        $time = $entry.Timestamp.ToLocalTime().ToString("HH:mm:ss")
        $color = $colors[$entry.Level] ?? "White"
        $symbol = $symbols[$entry.Level] ?? "•"
        
        # Build formatted string
        $parts = @(
            "[$time]"
            "$symbol $($entry.Message)"
        )
        
        return $parts -join " "
    }
    
    static [string] FormatJson([LogEntry]$entry) {
        return @{
            timestamp = $entry.Timestamp.ToString("o")
            level = $entry.Level
            message = $entry.Message
            context = $entry.Context
            source = $entry.Source
        } | ConvertTo-Json -Compress
    }
}

class Logger {
    hidden [string]$OutputLevel
    hidden [ConcurrentQueue[LogEntry]]$Queue
    hidden [string]$LogPath
    hidden [System.Threading.Timer]$FlushTimer
    hidden [hashtable]$Metrics = @{}
    hidden [object]$MetricsLock = [System.Threading.ReaderWriterLockSlim]::new()
    
    Logger([string]$outputLevel, [string]$projectPath) {
        $this.OutputLevel = $outputLevel
        $this.Queue = [ConcurrentQueue[LogEntry]]::new()
        $this.LogPath = Join-Path $projectPath "logs" "bushido-setup.log"
        $this.InitializeLogFile()
        $this.StartFlushTimer()
    }
    
    hidden [void] InitializeLogFile() {
        $logDir = Split-Path $this.LogPath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
    }
    
    hidden [void] StartFlushTimer() {
        $callback = {
            param($state)
            $logger = $state
            $logger.FlushToFile()
        }.GetNewClosure()
        
        $this.FlushTimer = [System.Threading.Timer]::new(
            $callback,
            $this,
            [TimeSpan]::FromSeconds(2),
            [TimeSpan]::FromSeconds(2)
        )
    }
    
    [void] Log([string]$message, [string]$level = "Info", [hashtable]$context = @{}) {
        $entry = [LogEntry]::new($level, $message, $context)
        
        # Update metrics
        $this.UpdateMetrics($level)
        
        # Output to console based on level
        if ($this.ShouldOutput($level)) {
            $this.WriteToConsole($entry)
        }
        
        # Queue for file output
        $this.Queue.Enqueue($entry)
    }
    
    hidden [bool] ShouldOutput([string]$level) {
        $levelMap = @{
            "Quiet" = @("Error", "Warning")
            "Normal" = @("Error", "Warning", "Success", "Info", "Stealth")
            "Detailed" = @("Error", "Warning", "Success", "Info", "Stealth", "Verbose")
            "Diagnostic" = @("Error", "Warning", "Success", "Info", "Stealth", "Verbose", "Debug")
        }
        
        return $level -in $levelMap[$this.OutputLevel]
    }
    
    hidden [void] WriteToConsole([LogEntry]$entry) {
        $formatted = [LogFormatter]::FormatConsole($entry)
        $colors = @{
            "Error" = "Red"
            "Warning" = "Yellow"
            "Success" = "Green"
            "Info" = "Cyan"
            "Verbose" = "Blue"
            "Debug" = "DarkGray"
            "Stealth" = "Magenta"
        }
        
        $time = $entry.Timestamp.ToLocalTime().ToString("HH:mm:ss")
        Write-Host "[$time] " -NoNewline -ForegroundColor DarkGray
        
        $parts = $formatted -split " ", 2
        Write-Host $parts[1] -ForegroundColor ($colors[$entry.Level] ?? "White")
        
        # Show context in diagnostic mode
        if ($this.OutputLevel -eq "Diagnostic" -and $entry.Context.Count -gt 0) {
            Write-Host "         Context: " -NoNewline -ForegroundColor DarkGray
            Write-Host ($entry.Context | ConvertTo-Json -Compress) -ForegroundColor DarkGray
        }
    }
    
    hidden [void] UpdateMetrics([string]$level) {
        $this.MetricsLock.EnterWriteLock()
        try {
            $key = "Level_$level"
            if ($this.Metrics.ContainsKey($key)) {
                $this.Metrics[$key]++
            } else {
                $this.Metrics[$key] = 1
            }
        }
        finally {
            $this.MetricsLock.ExitWriteLock()
        }
    }
    
    [void] FlushToFile() {
        $entries = @()
        $entry = $null
        
        while ($this.Queue.TryDequeue([ref]$entry)) {
            $entries += [LogFormatter]::FormatJson($entry)
        }
        
        if ($entries.Count -gt 0) {
            Add-Content -Path $this.LogPath -Value ($entries -join "`n") -Encoding UTF8
        }
    }
    
    [hashtable] GetMetrics() {
        $this.MetricsLock.EnterReadLock()
        try {
            return $this.Metrics.Clone()
        }
        finally {
            $this.MetricsLock.ExitReadLock()
        }
    }
    
    [void] Dispose() {
        $this.FlushTimer?.Dispose()
        $this.FlushToFile()
        $this.MetricsLock?.Dispose()
    }
}

# ═══════════════════════════════════════════════════════════════════
# File System Abstraction with Builder Pattern
# ═══════════════════════════════════════════════════════════════════

class FileBuilder {
    hidden [string]$Path
    hidden [string]$Content
    hidden [string]$Encoding = "UTF8"
    hidden [bool]$CreateBackup = $false
    
    FileBuilder([string]$path) {
        $this.Path = $path
    }
    
    [FileBuilder] WithContent([string]$content) {
        $this.Content = $content
        return $this
    }
    
    [FileBuilder] WithJson([object]$obj) {
        $this.Content = $obj | ConvertTo-Json -Depth 10 -Compress:$false
        return $this
    }
    
    [FileBuilder] WithYaml([hashtable]$data) {
        # Simple YAML generation for our use case
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
        $this.Content = $yaml
        return $this
    }
    
    [FileBuilder] WithBackup() {
        $this.CreateBackup = $true
        return $this
    }
    
    [Result] Build() {
        try {
            # Ensure directory exists
            $dir = Split-Path $this.Path -Parent
            if ($dir -and -not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            
            # Create backup if requested and file exists
            if ($this.CreateBackup -and (Test-Path $this.Path)) {
                $backupPath = "$($this.Path).backup"
                Copy-Item -Path $this.Path -Destination $backupPath -Force
            }
            
            # Atomic write using temporary file
            $tempPath = "$($this.Path).tmp"
            Set-Content -Path $tempPath -Value $this.Content -Encoding $this.Encoding -NoNewline
            Move-Item -Path $tempPath -Destination $this.Path -Force
            
            return [Result]::Ok(@{
                Path = $this.Path
                Size = (Get-Item $this.Path).Length
                Created = [DateTime]::Now
            })
        }
        catch {
            return [Result]::Fail("Failed to create file '$($this.Path)': $_")
        }
    }
}

# ═══════════════════════════════════════════════════════════════════
# Command Pattern with Transaction Support
# ═══════════════════════════════════════════════════════════════════

class SetupCommand {
    [string]$Name
    [scriptblock]$Execute
    [scriptblock]$Rollback
    [bool]$Executed = $false
    
    SetupCommand([string]$name, [scriptblock]$execute, [scriptblock]$rollback) {
        $this.Name = $name
        $this.Execute = $execute
        $this.Rollback = $rollback
    }
    
    [Result] Run() {
        try {
            $result = & $this.Execute
            $this.Executed = $true
            return [Result]::Ok($result)
        }
        catch {
            return [Result]::Fail("Command '$($this.Name)' failed: $_")
        }
    }
    
    [void] Undo() {
        if ($this.Executed -and $this.Rollback) {
            try {
                & $this.Rollback
                $this.Executed = $false
            }
            catch {
                # Rollback errors are logged but don't throw
            }
        }
    }
}

class SetupTransaction {
    [List[SetupCommand]]$Commands
    [Logger]$Logger
    
    SetupTransaction([Logger]$logger) {
        $this.Commands = [List[SetupCommand]]::new()
        $this.Logger = $logger
    }
    
    [void] Add([SetupCommand]$command) {
        $this.Commands.Add($command)
    }
    
    [Result] Execute() {
        $executed = [List[SetupCommand]]::new()
        
        foreach ($command in $this.Commands) {
            $this.Logger.Log("Executing: $($command.Name)", "Verbose")
            
            $result = $command.Run()
            if ($result.Success) {
                $executed.Add($command)
                $this.Logger.Log("✓ $($command.Name)", "Success")
            }
            else {
                $this.Logger.Log("Failed: $($command.Name)", "Error", @{ Error = $result.Error })
                
                # Rollback in reverse order
                $executed.Reverse()
                foreach ($cmd in $executed) {
                    $this.Logger.Log("Rolling back: $($cmd.Name)", "Warning")
                    $cmd.Undo()
                }
                
                return $result
            }
        }
        
        return [Result]::Ok("All commands executed successfully")
    }
}

# ═══════════════════════════════════════════════════════════════════
# Project Structure Generators
# ═══════════════════════════════════════════════════════════════════

class ContractGenerator {
    static [string] GenerateMainContract([hashtable]$config) {
        return @"
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title BushidoNFT
 * @author Bushido Development Team
 * @notice Interactive NFT with integrated voting for episodic storytelling
 * @dev Gas-optimized implementation for Abstract L2
 */
contract BushidoNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    
    // Immutable configuration
    uint256 public constant MAX_SUPPLY = $($config.TotalSupply);
    uint256 public constant TOKENS_PER_CLAN = $($config.TokensPerClan);
    uint256 public constant MINT_PRICE = $($config.MintPrice) ether;
    uint256 public constant MAX_PER_WALLET = $($config.MaxPerWallet);
    uint256 public constant TOTAL_CLANS = $($config.ClansCount);
    
    // State variables
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => uint8) public tokenClan;
    mapping(uint256 => uint8) public tokenRarity;
    mapping(address => uint256) public mintedPerWallet;
    mapping(uint256 => mapping(uint256 => bool)) public hasVoted;
    mapping(uint256 => mapping(uint8 => uint256)) public episodeVotes;
    
    string private _baseTokenURI;
    uint256 public currentEpisode = 1;
    bool public mintActive;
    uint256 public mintStartTime;
    
    // Events
    event MintActivated(uint256 timestamp);
    event TokenMinted(address indexed to, uint256 indexed tokenId, uint8 clan, uint8 rarity);
    event VoteCast(uint256 indexed tokenId, uint256 indexed episode, uint8 choice, uint256 power);
    event EpisodeProgressed(uint256 indexed newEpisode, uint256 timestamp);
    
    constructor(string memory baseURI) ERC721("Bushido", "BUSHIDO") {
        _baseTokenURI = baseURI;
    }
    
    /**
     * @notice Activates the stealth mint
     * @dev Can only be called once by owner
     */
    function activateMint() external onlyOwner {
        require(!mintActive, "Mint already active");
        mintActive = true;
        mintStartTime = block.timestamp;
        emit MintActivated(block.timestamp);
    }
    
    /**
     * @notice Mints NFTs with clan assignment based on token ID
     * @param quantity Number of NFTs to mint (max 3)
     */
    function mint(uint256 quantity) external payable nonReentrant {
        require(mintActive, "Mint not active");
        require(quantity > 0 && quantity <= MAX_PER_WALLET, "Invalid quantity");
        require(mintedPerWallet[msg.sender] + quantity <= MAX_PER_WALLET, "Exceeds wallet limit");
        require(_tokenIdCounter.current() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        require(msg.value >= MINT_PRICE * quantity, "Insufficient payment");
        
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            
            // Deterministic clan assignment
            uint8 clan = uint8((tokenId - 1) / TOKENS_PER_CLAN);
            require(clan < TOTAL_CLANS, "Invalid clan assignment");
            
            // Generate rarity with on-chain randomness
            uint8 rarity = _generateRarity(tokenId);
            
            tokenClan[tokenId] = clan;
            tokenRarity[tokenId] = rarity;
            
            _safeMint(msg.sender, tokenId);
            emit TokenMinted(msg.sender, tokenId, clan, rarity);
        }
        
        mintedPerWallet[msg.sender] += quantity;
    }
    
    /**
     * @notice Casts a vote for the current episode
     * @param tokenId NFT used for voting
     * @param choice Vote choice (1-4)
     */
    function castVote(uint256 tokenId, uint8 choice) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        require(!hasVoted[tokenId][currentEpisode], "Already voted this episode");
        require(choice > 0 && choice <= 4, "Invalid choice");
        
        hasVoted[tokenId][currentEpisode] = true;
        
        // Calculate voting power: rarity^2
        uint256 power = uint256(tokenRarity[tokenId]) ** 2;
        episodeVotes[currentEpisode][choice] += power;
        
        emit VoteCast(tokenId, currentEpisode, choice, power);
    }
    
    /**
     * @notice Progresses to the next episode
     * @dev Only owner can progress episodes
     */
    function progressEpisode() external onlyOwner {
        currentEpisode++;
        emit EpisodeProgressed(currentEpisode, block.timestamp);
    }
    
    /**
     * @notice Gets voting results for an episode
     * @param episode Episode number
     * @return results Array of vote counts for each choice
     */
    function getEpisodeResults(uint256 episode) external view returns (uint256[5] memory results) {
        for (uint8 i = 1; i <= 4; i++) {
            results[i] = episodeVotes[episode][i];
        }
    }
    
    /**
     * @notice Gets the voting power of a token
     * @param tokenId Token to check
     * @return power Voting power (rarity^2)
     */
    function getVotingPower(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return uint256(tokenRarity[tokenId]) ** 2;
    }
    
    /**
     * @dev Generates rarity based on pseudo-random distribution
     */
    function _generateRarity(uint256 tokenId) private view returns (uint8) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            tokenId,
            msg.sender,
            _tokenIdCounter.current()
        )));
        
        uint256 rand = seed % 10000; // 0-9999 for precision
        
        if (rand < 100) return 5;    // Legendary (1%)
        if (rand < 500) return 4;    // Epic (4%)
        if (rand < 1500) return 3;   // Rare (10%)
        if (rand < 3500) return 2;   // Uncommon (20%)
        return 1;                     // Common (65%)
    }
    
    /**
     * @dev Base URI for token metadata
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    /**
     * @dev Check if token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
    
    /**
     * @notice Updates base URI for metadata
     * @param newURI New base URI
     */
    function setBaseURI(string memory newURI) external onlyOwner {
        _baseTokenURI = newURI;
    }
    
    /**
     * @notice Withdraws contract balance to owner
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
}
"@
    }
    
    static [string] GenerateHardhatConfig() {
        return @'
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import * as dotenv from "dotenv";

dotenv.config();

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
      viaIR: true
    }
  },
  networks: {
    hardhat: {
      chainId: 1337,
      mining: {
        auto: true,
        interval: 0
      }
    },
    abstractTestnet: {
      url: process.env.ABSTRACT_TESTNET_RPC || "https://api.testnet.abs.xyz",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11124
    },
    abstract: {
      url: process.env.ABSTRACT_RPC || "https://api.abs.xyz",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11125
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    currency: "USD",
    gasPrice: 20
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    strict: true
  },
  etherscan: {
    apiKey: {
      abstract: process.env.ABSTRACT_EXPLORER_API_KEY || ""
    }
  }
};

export default config;
'@
    }
}

class FrontendGenerator {
    static [string] GenerateStealthPage() {
        return @'
'use client';

import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const CLANS = [
  { id: 0, name: 'Dragon', symbol: '🐉', virtue: 'Courage', color: '#DC2626' },
  { id: 1, name: 'Phoenix', symbol: '🔥', virtue: 'Rebirth', color: '#F59E0B' },
  { id: 2, name: 'Tiger', symbol: '🐅', virtue: 'Strength', color: '#F97316' },
  { id: 3, name: 'Serpent', symbol: '🐍', virtue: 'Wisdom', color: '#8B5CF6' },
  { id: 4, name: 'Eagle', symbol: '🦅', virtue: 'Vision', color: '#3B82F6' },
  { id: 5, name: 'Wolf', symbol: '🐺', virtue: 'Loyalty', color: '#6B7280' },
  { id: 6, name: 'Bear', symbol: '🐻', virtue: 'Protection', color: '#92400E' },
  { id: 7, name: 'Lion', symbol: '🦁', virtue: 'Leadership', color: '#EAB308' }
];

export default function StealthCountdown() {
  const [timeLeft, setTimeLeft] = useState({ days: 0, hours: 0, minutes: 0, seconds: 0 });
  const [hoveredClan, setHoveredClan] = useState<number | null>(null);
  const [glitchText, setGlitchText] = useState('');
  
  // Countdown logic
  useEffect(() => {
    const launchTime = new Date(process.env.NEXT_PUBLIC_LAUNCH_TIME || '2024-12-25T00:00:00Z');
    
    const timer = setInterval(() => {
      const now = new Date().getTime();
      const distance = launchTime.getTime() - now;
      
      if (distance > 0) {
        setTimeLeft({
          days: Math.floor(distance / (1000 * 60 * 60 * 24)),
          hours: Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)),
          minutes: Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60)),
          seconds: Math.floor((distance % (1000 * 60)) / 1000)
        });
      } else {
        clearInterval(timer);
        window.location.href = '/mint';
      }
    }, 1000);
    
    return () => clearInterval(timer);
  }, []);
  
  // Glitch effect
  useEffect(() => {
    const messages = [
      'Eight clans. Eight virtues. One destiny.',
      'The way of the warrior awaits...',
      'Honor is not given. It is earned.',
      'Legends are forged in the choices we make.'
    ];
    
    const interval = setInterval(() => {
      setGlitchText(messages[Math.floor(Math.random() * messages.length)]);
    }, 5000);
    
    return () => clearInterval(interval);
  }, []);
  
  // Matrix rain effect
  const MatrixRain = () => {
    const [drops, setDrops] = useState<Array<{ x: number; y: number; speed: number }>>([]);
    
    useEffect(() => {
      const newDrops = Array.from({ length: 50 }, () => ({
        x: Math.random() * window.innerWidth,
        y: Math.random() * -window.innerHeight,
        speed: Math.random() * 2 + 1
      }));
      setDrops(newDrops);
    }, []);
    
    return (
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        {drops.map((drop, i) => (
          <motion.div
            key={i}
            className="absolute text-red-500/20 text-xs font-mono"
            initial={{ x: drop.x, y: drop.y }}
            animate={{ y: window.innerHeight + 100 }}
            transition={{
              duration: 20 / drop.speed,
              repeat: Infinity,
              ease: 'linear'
            }}
          >
            武士道
          </motion.div>
        ))}
      </div>
    );
  };
  
  return (
    <div className="min-h-screen bg-black text-white relative overflow-hidden">
      {/* Background effects */}
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-gradient-to-br from-red-950/20 via-black to-red-950/20" />
        <MatrixRain />
      </div>
      
      {/* Floating clan symbols */}
      <div className="absolute inset-0">
        {CLANS.map((clan, i) => (
          <motion.div
            key={clan.id}
            className="absolute text-6xl opacity-5"
            initial={{ 
              x: Math.random() * window.innerWidth,
              y: -100,
              rotate: 0
            }}
            animate={{
              y: window.innerHeight + 100,
              rotate: 360,
              x: Math.sin(i) * 100 + Math.random() * window.innerWidth
            }}
            transition={{
              duration: 20 + Math.random() * 10,
              repeat: Infinity,
              delay: i * 2.5,
              ease: 'linear'
            }}
          >
            {clan.symbol}
          </motion.div>
        ))}
      </div>
      
      {/* Main content */}
      <div className="relative z-10 min-h-screen flex flex-col items-center justify-center px-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center max-w-4xl"
        >
          {/* Title with glitch effect */}
          <motion.h1 
            className="text-7xl md:text-8xl font-bold mb-4 relative"
            animate={{ 
              textShadow: [
                '0 0 0px rgba(220, 38, 38, 0)',
                '0 0 20px rgba(220, 38, 38, 0.5)',
                '0 0 0px rgba(220, 38, 38, 0)'
              ]
            }}
            transition={{ duration: 2, repeat: Infinity }}
          >
            <span className="relative">
              BUSHIDO
              <motion.span
                className="absolute inset-0 text-red-500"
                animate={{ 
                  opacity: [0, 0.7, 0],
                  x: [-2, 2, -2]
                }}
                transition={{ duration: 0.2, repeat: Infinity, repeatDelay: 5 }}
              >
                BUSHIDO
              </motion.span>
            </span>
          </motion.h1>
          
          <motion.p 
            className="text-xl text-gray-400 mb-12"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.5 }}
          >
            The Way of the Warrior Awaits
          </motion.p>
          
          {/* Countdown */}
          <div className="grid grid-cols-4 gap-4 md:gap-8 mb-16">
            {Object.entries(timeLeft).map(([unit, value], i) => (
              <motion.div
                key={unit}
                initial={{ scale: 0, rotate: -180 }}
                animate={{ scale: 1, rotate: 0 }}
                transition={{ delay: i * 0.1, type: 'spring' }}
                className="relative"
              >
                <div className="bg-black/50 backdrop-blur-sm border border-red-900/30 rounded-lg p-4 md:p-6">
                  <div className="text-3xl md:text-5xl font-mono font-bold text-red-500">
                    {value.toString().padStart(2, '0')}
                  </div>
                  <div className="text-xs md:text-sm uppercase tracking-widest text-gray-500 mt-2">
                    {unit}
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
          
          {/* Glitch text */}
          <AnimatePresence mode="wait">
            <motion.p
              key={glitchText}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              className="text-gray-500 italic mb-12"
            >
              "{glitchText}"
            </motion.p>
          </AnimatePresence>
          
          {/* Clan preview */}
          <div className="flex flex-wrap justify-center gap-4">
            {CLANS.map((clan) => (
              <motion.div
                key={clan.id}
                className="relative cursor-pointer"
                onHoverStart={() => setHoveredClan(clan.id)}
                onHoverEnd={() => setHoveredClan(null)}
                whileHover={{ scale: 1.2 }}
                whileTap={{ scale: 0.9 }}
              >
                <motion.div
                  className="text-3xl opacity-30 hover:opacity-100 transition-opacity"
                  animate={hoveredClan === clan.id ? {
                    textShadow: `0 0 20px ${clan.color}`
                  } : {}}
                >
                  {clan.symbol}
                </motion.div>
                
                <AnimatePresence>
                  {hoveredClan === clan.id && (
                    <motion.div
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: 10 }}
                      className="absolute -bottom-8 left-1/2 transform -translate-x-1/2 whitespace-nowrap"
                    >
                      <span className="text-sm" style={{ color: clan.color }}>
                        {clan.virtue}
                      </span>
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.div>
            ))}
          </div>
        </motion.div>
        
        {/* Connect wallet teaser */}
        <motion.div
          className="absolute bottom-8 left-1/2 transform -translate-x-1/2"
          initial={{ opacity: 0 }}
          animate={{ opacity: 0.3 }}
          transition={{ delay: 2 }}
        >
          <div className="text-gray-600 text-sm">
            Abstract L2 • 0.08 ETH • Max 3 per wallet
          </div>
        </motion.div>
      </div>
    </div>
  );
}
'@
    }
}

# ═══════════════════════════════════════════════════════════════════
# Main Project Builder
# ═══════════════════════════════════════════════════════════════════

class BushidoProjectBuilder {
    [string]$ProjectPath
    [Logger]$Logger
    [SetupTransaction]$Transaction
    
    BushidoProjectBuilder([string]$projectPath, [Logger]$logger) {
        $this.ProjectPath = $projectPath
        $this.Logger = $logger
        $this.Transaction = [SetupTransaction]::new($logger)
    }
    
    [Result] Build() {
        # Create project directory if needed
        if ($this.ProjectPath -ne (Get-Location).Path) {
            $createDir = [SetupCommand]::new(
                "Create project directory",
                { New-Item -ItemType Directory -Path $this.ProjectPath -Force | Out-Null },
                { Remove-Item -Path $this.ProjectPath -Recurse -Force -ErrorAction SilentlyContinue }
            )
            $this.Transaction.Add($createDir)
        }
        
        # Add all setup commands
        $this.AddRootStructureCommands()
        $this.AddContractsCommands()
        $this.AddFrontendCommands()
        $this.AddBackendCommands()
        $this.AddScriptsCommands()
        $this.AddConfigurationCommands()
        
        # Execute transaction
        return $this.Transaction.Execute()
    }
    
    hidden [void] AddRootStructureCommands() {
        # Root package.json
        $rootPackage = @{
            name = [BushidoConfig]::Project.Name
            version = "1.0.0"
            private = $true
            type = "module"
            description = "Interactive NFT Anime • Web3 Storytelling"
            author = "Bushido Development Team"
            scripts = @{
                "dev" = "turbo run dev --parallel"
                "dev:stealth" = "turbo run dev --filter=@bushido/frontend -- --port 3000"
                "build" = "turbo run build"
                "test" = "turbo run test"
                "lint" = "turbo run lint"
                "format" = "prettier --write '**/*.{js,jsx,ts,tsx,json,sol,md}'"
                "clean" = "turbo run clean && rimraf node_modules .turbo"
                "deploy:testnet" = "turbo run deploy --filter=@bushido/contracts -- --network abstractTestnet"
                "deploy:mainnet" = "turbo run deploy --filter=@bushido/contracts -- --network abstract"
                "launch:countdown" = "pnpm run build --filter=@bushido/frontend && vercel --prod"
            }
            devDependencies = @{
                "turbo" = "latest"
                "prettier" = "^3.2.5"
                "rimraf" = "^5.0.5"
                "vercel" = "^32.7.2"
                "@changesets/cli" = "^2.27.1"
            }
            engines = @{
                node = ">=18.0.0"
                pnpm = ">=8.0.0"
            }
        }
        
        $this.Transaction.Add([SetupCommand]::new(
            "Create root package.json",
            { 
                [FileBuilder]::new("package.json")
                    .WithJson($rootPackage)
                    .Build()
                    .Unwrap()
            },
            { Remove-Item "package.json" -Force -ErrorAction SilentlyContinue }
        ))
        
        # Workspace configuration
        $workspace = @{
            packages = @("contracts", "frontend", "backend", "scripts", "episodes")
        }
        
        $this.Transaction.Add([SetupCommand]::new(
            "Create pnpm workspace",
            {
                [FileBuilder]::new("pnpm-workspace.yaml")
                    .WithYaml($workspace)
                    .Build()
                    .Unwrap()
            },
            { Remove-Item "pnpm-workspace.yaml" -Force -ErrorAction SilentlyContinue }
        ))
        
        # Turbo configuration
        $turbo = @{
            '$schema' = "https://turbo.build/schema.json"
            globalDependencies = @(".env", ".env.local")
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
                lint = @{
                    outputs = @()
                }
                deploy = @{
                    dependsOn = @("build", "test")
                    cache = $false
                }
            }
        }
        
        $this.Transaction.Add([SetupCommand]::new(
            "Create turbo.json",
            {
                [FileBuilder]::new("turbo.json")
                    .WithJson($turbo)
                    .Build()
                    .Unwrap()
            },
            { Remove-Item "turbo.json" -Force -ErrorAction SilentlyContinue }
        ))
    }
    
    hidden [void] AddContractsCommands() {
        $contractsPath = Join-Path $this.ProjectPath "contracts"
        
        # Create contracts directory
        $this.Transaction.Add([SetupCommand]::new(
            "Create contracts directory",
            { New-Item -ItemType Directory -Path $contractsPath -Force | Out-Null },
            { Remove-Item $contractsPath -Recurse -Force -ErrorAction SilentlyContinue }
        ))
        
        # Subdirectories
        @("contracts", "contracts/interfaces", "contracts/libraries", "scripts", "test") | ForEach-Object {
            $subPath = Join-Path $contractsPath $_
            $this.Transaction.Add([SetupCommand]::new(
                "Create $_ directory",
                { New-Item -ItemType Directory -Path $subPath -Force | Out-Null },
                { Remove-Item $subPath -Recurse -Force -ErrorAction SilentlyContinue }
            ))
        }
        
        # Package.json
        $contractsPackage = @{
            name = "@bushido/contracts"
            version = "1.0.0"
            private = $true
            scripts = @{
                "compile" = "hardhat compile"
                "test" = "hardhat test"
                "coverage" = "hardhat coverage"
                "deploy" = "hardhat run scripts/deploy.ts"
                "verify" = "hardhat verify"
                "size" = "hardhat size-contracts"
                "clean" = "hardhat clean && rimraf artifacts cache typechain-types"
            }
            devDependencies = @{
                "hardhat" = "^2.19.4"
                "@nomicfoundation/hardhat-toolbox" = "^4.0.0"
                "@openzeppelin/contracts" = "^5.0.1"
                "hardhat-contract-sizer" = "^2.10.0"
                "hardhat-gas-reporter" = "^1.0.9"
                "dotenv" = "^16.3.1"
            }
        }
        
        $this.Transaction.Add([SetupCommand]::new(
            "Create contracts package.json",
            {
                [FileBuilder]::new((Join-Path $contractsPath "package.json"))
                    .WithJson($contractsPackage)
                    .Build()
                    .Unwrap()
            },
            { Remove-Item (Join-Path $contractsPath "package.json") -Force -ErrorAction SilentlyContinue }
        ))
        
        # Main contract
        $this.Transaction.Add([SetupCommand]::new(
            "Create BushidoNFT contract",
            {
                $contractCode = [ContractGenerator]::GenerateMainContract([BushidoConfig]::Project)
                [FileBuilder]::new((Join-Path $contractsPath "contracts/BushidoNFT.sol"))
                    .WithContent($contractCode)
                    .Build()
                    .Unwrap()
            },
            { Remove-Item (Join-Path $contractsPath "contracts/BushidoNFT.sol") -Force -ErrorAction SilentlyContinue }
        ))
        
        # Hardhat config
        $this.Transaction.Add([SetupCommand]::new(
            "Create Hardhat config",
            {
                $config = [ContractGenerator]::GenerateHardhatConfig()
                [FileBuilder]::new((Join-Path $contractsPath "hardhat.config.ts"))
                    .WithContent($config)
                    .Build()
                    .Unwrap()
            },
            { Remove-Item (Join-Path $contractsPath "hardhat.config.ts") -Force -ErrorAction SilentlyContinue }
        ))
    }
    
    hidden [void] AddFrontendCommands() {
        $frontendPath = Join-Path $this.ProjectPath "frontend"
        
        # Create frontend directory
        $this.Transaction.Add([SetupCommand]::new(
            "Create frontend directory",
            { New-Item -ItemType Directory -Path $frontendPath -Force | Out-Null },
            { Remove-Item $frontendPath -Recurse -Force -ErrorAction SilentlyContinue }
        ))
        
        # Package.json
        $frontendPackage = @{
            name = "@bushido/frontend"
            version = "1.0.0"
            private = $true
            scripts = @{
                "dev" = "next dev"
                "build" = "next build"
                "start" = "next start"
                "lint" = "next lint"
                "analyze" = "ANALYZE=true next build"
            }
            dependencies = @{
                "next" = "14.1.0"
                "react" = "^18.2.0"
                "react-dom" = "^18.2.0"
                "wagmi" = "^2.5.7"
                "viem" = "^2.7.6"
                "@rainbow-me/rainbowkit" = "^2.0.0"
                "framer-motion" = "^11.0.3"
                "lucide-react" = "^0.312.0"
            }
            devDependencies = @{
                "@types/node" = "^20.11.0"
                "@types/react" = "^18.2.48"
                "typescript" = "^5.3.3"
                "tailwindcss" = "^3.4.1"
                "autoprefixer" = "^10.4.17"
                "postcss" = "^8.4.33"
            }
        }
        
        $this.Transaction.Add([SetupCommand]::new(
            "Create frontend package.json",
            {
                [FileBuilder]::new((Join-Path $frontendPath "package.json"))
                    .WithJson($frontendPackage)
                    .Build()
                    .Unwrap()
            },
            { Remove-Item (Join-Path $frontendPath "package.json") -Force -ErrorAction SilentlyContinue }
        ))
        
        # Create app structure
        @("src", "src/app", "src/components", "src/lib", "public") | ForEach-Object {
            $subPath = Join-Path $frontendPath $_
            $this.Transaction.Add([SetupCommand]::new(
                "Create frontend/$_ directory",
                { New-Item -ItemType Directory -Path $subPath -Force | Out-Null },
                { Remove-Item $subPath -Recurse -Force -ErrorAction SilentlyContinue }
            ))
        }
        
        # Stealth countdown page
        $this.Transaction.Add([SetupCommand]::new(
            "Create stealth countdown page",
            {
                $pagePath = Join-Path $frontendPath "src/app"
                New-Item -ItemType Directory -Path $pagePath -Force | Out-Null
                
                $pageCode = [FrontendGenerator]::GenerateStealthPage()
                [FileBuilder]::new((Join-Path $pagePath "page.tsx"))
                    .WithContent($pageCode)
                    .Build()
                    .Unwrap()
            },
            { Remove-Item (Join-Path $frontendPath "src/app/page.tsx") -Force -ErrorAction SilentlyContinue }
        ))
    }
    
    hidden [void] AddBackendCommands() {
        $backendPath = Join-Path $this.ProjectPath "backend"
        
        $this.Transaction.Add([SetupCommand]::new(
            "Create backend structure",
            {
                New-Item -ItemType Directory -Path $backendPath -Force | Out-Null
                
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
                
                $fileBuilder = [FileBuilder]::new((Join-Path $backendPath "package.json"))
                $fileBuilder.WithJson($package).Build().Unwrap()
            },
            { Remove-Item $backendPath -Recurse -Force -ErrorAction SilentlyContinue }
        ))
    }
    
    hidden [void] AddScriptsCommands() {
        $scriptsPath = Join-Path $this.ProjectPath "scripts"
        
        $this.Transaction.Add([SetupCommand]::new(
            "Create scripts structure",
            {
                New-Item -ItemType Directory -Path $scriptsPath -Force | Out-Null
                
                $package = @{
                    name = "@bushido/scripts"
                    version = "1.0.0"
                    private = $true
                    scripts = @{
                        "generate-metadata" = "ts-node src/generate-metadata.ts"
                        "reveal-lore" = "ts-node src/reveal-lore.ts"
                    }
                    devDependencies = @{
                        "typescript" = "^5.3.3"
                        "ts-node" = "^10.9.2"
                        "ipfs-http-client" = "^60.0.1"
                        "chalk" = "^5.3.0"
                    }
                }
                
                [FileBuilder]::new((Join-Path $scriptsPath "package.json"))
                    .WithJson($package)
                    .Build()
                    .Unwrap()
            },
            { Remove-Item $scriptsPath -Recurse -Force -ErrorAction SilentlyContinue }
        ))
    }
    
    hidden [void] AddConfigurationCommands() {
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
typechain-types/

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

# Stealth
stealth-config.json
kol-list.json
"@
        
        $this.Transaction.Add([SetupCommand]::new(
            "Create .gitignore",
            {
                [FileBuilder]::new(".gitignore")
                    .WithContent($gitignore)
                    .Build()
                    .Unwrap()
            },
            { Remove-Item ".gitignore" -Force -ErrorAction SilentlyContinue }
        ))
        
        # .env.example
        $env = @"
# Network Configuration
ABSTRACT_RPC=https://api.abs.xyz
ABSTRACT_TESTNET_RPC=https://api.testnet.abs.xyz
PRIVATE_KEY=your_private_key_here

# Contract
CONTRACT_ADDRESS=
IPFS_BASE_URI=

# Frontend
NEXT_PUBLIC_NETWORK=abstract
NEXT_PUBLIC_CONTRACT_ADDRESS=
NEXT_PUBLIC_LAUNCH_TIME=2024-12-25T00:00:00Z

# Backend
REDIS_URL=redis://localhost:6379
PORT=4000

# IPFS
PINATA_API_KEY=
PINATA_SECRET_KEY=

# Analytics
NEXT_PUBLIC_GA_ID=

# Vercel
VERCEL_TOKEN=
"@
        
        $this.Transaction.Add([SetupCommand]::new(
            "Create .env.example",
            {
                [FileBuilder]::new(".env.example")
                    .WithContent($env)
                    .Build()
                    .Unwrap()
            },
            { Remove-Item ".env.example" -Force -ErrorAction SilentlyContinue }
        ))
        
        # README.md
        $readme = @"
# 🏯 Bushido NFT - Interactive Anime Storytelling

> *"Eight clans. Eight virtues. One destiny."*

An innovative NFT project that combines digital collectibles with episodic anime storytelling, where holders shape the narrative through on-chain voting.

## 🥷 Stealth Launch Strategy

- **Phase 1**: Countdown timer with cryptic messaging
- **Phase 2**: Mint activation (1,600 NFTs @ 0.08 ETH)
- **Phase 3**: Lore reveal & clan descriptions
- **Phase 4**: Episode 1 premiere & voting activation

## 🚀 Quick Start

\`\`\`bash
# Install dependencies
pnpm install

# Configure environment
cp .env.example .env
# Edit .env with your configuration

# Deploy to testnet
pnpm deploy:testnet

# Start development
pnpm dev
\`\`\`

## 🎭 The Eight Clans

$(
    [BushidoConfig]::Clans | ForEach-Object {
        "$($_.Id + 1). **$($_.Name)** ($($_.Symbol)) - $($_.Virtue)"
    }
)

## 🗳️ Voting Power

$(
    [BushidoConfig]::RarityTiers.GetEnumerator() | Sort-Object { $_.Value.Id } | ForEach-Object {
        "- **$($_.Key)**: $($_.Value.Power) voting power ($($_.Value.Percentage)%)"
    }
)

## 📺 Episode System

Weekly episodes with community-driven plot decisions. Each episode ends with 4 choices that shape the next chapter.

## 🛠️ Tech Stack

- **Blockchain**: Abstract L2
- **Smart Contracts**: Solidity + Hardhat
- **Frontend**: Next.js 14 + TypeScript
- **Web3**: Wagmi + RainbowKit
- **Backend**: Express.js + Redis
- **Storage**: IPFS (Pinata)

## 📄 License

MIT License
"@
        
        $this.Transaction.Add([SetupCommand]::new(
            "Create README.md",
            {
                [FileBuilder]::new("README.md")
                    .WithContent($readme)
                    .Build()
                    .Unwrap()
            },
            { Remove-Item "README.md" -Force -ErrorAction SilentlyContinue }
        ))
    }
}

# ═══════════════════════════════════════════════════════════════════
# Main Orchestrator
# ═══════════════════════════════════════════════════════════════════

class SetupOrchestrator {
    [string]$ProjectPath
    [Logger]$Logger
    [BushidoProjectBuilder]$Builder
    
    SetupOrchestrator([string]$projectPath, [string]$outputLevel) {
        $this.ProjectPath = $projectPath
        $this.Logger = [Logger]::new($outputLevel, $projectPath)
        $this.Builder = [BushidoProjectBuilder]::new($projectPath, $this.Logger)
    }
    
    [Result] ValidatePrerequisites() {
        $this.Logger.Log("Validating prerequisites", "Info")
        
        foreach ($tool in [BushidoConfig]::Prerequisites.GetEnumerator()) {
            try {
                $output = & $tool.Value.Command 2>&1 | Out-String
                
                if ($output -match $tool.Value.Pattern) {
                    $version = [Version]$Matches[1]
                    
                    if ($version -ge $tool.Value.MinVersion) {
                        $this.Logger.Log("✓ $($tool.Key) $version", "Success", @{
                            Tool = $tool.Key
                            Version = $version.ToString()
                        })
                    }
                    else {
                        return [Result]::Fail($tool.Value.ErrorMsg)
                    }
                }
                else {
                    return [Result]::Fail("Could not parse version for $($tool.Key)")
                }
            }
            catch {
                return [Result]::Fail($tool.Value.ErrorMsg)
            }
        }
        
        return [Result]::Ok($null)
    }
    
    [Result] Execute() {
        try {
            # Change to project directory if needed
            if ($this.ProjectPath -ne (Get-Location).Path) {
                Set-Location $this.ProjectPath
            }
            
            # Build the project
            return $this.Builder.Build()
        }
        catch {
            $this.Logger.Log("Fatal error during setup", "Error", @{
                Error = $_.Exception.Message
                StackTrace = $_.ScriptStackTrace
            })
            return [Result]::Fail($_.Exception.Message)
        }
    }
    
    [void] Dispose() {
        $this.Logger.Dispose()
    }
}

# ═══════════════════════════════════════════════════════════════════
# Beautiful CLI Functions
# ═══════════════════════════════════════════════════════════════════

function Show-Banner {
    Clear-Host
    
    $banner = @"

    ██████╗ ██╗   ██╗███████╗██╗  ██╗██╗██████╗  ██████╗ 
    ██╔══██╗██║   ██║██╔════╝██║  ██║██║██╔══██╗██╔═══██╗
    ██████╔╝██║   ██║███████╗███████║██║██║  ██║██║   ██║
    ██╔══██╗██║   ██║╚════██║██╔══██║██║██║  ██║██║   ██║
    ██████╔╝╚██████╔╝███████║██║  ██║██║██████╔╝╚██████╔╝
    ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝ 
                                                            
           Interactive NFT Anime • Web3 Storytelling
                    
"@
    
    Write-Host $banner -ForegroundColor Red
    Write-Host "    🥷 Stealth Launch Edition | Abstract L2 Ready" -ForegroundColor Magenta
    Write-Host "    ═══════════════════════════════════════════════════`n" -ForegroundColor DarkRed
}

function Show-Configuration {
    Write-Host "    📋 Project Configuration:" -ForegroundColor Yellow
    Write-Host "       Supply:         " -NoNewline -ForegroundColor White
    Write-Host "$([BushidoConfig]::Project.TotalSupply) NFTs" -ForegroundColor DarkGray
    Write-Host "       Structure:      " -NoNewline -ForegroundColor White
    Write-Host "$([BushidoConfig]::Project.ClansCount) clans × $([BushidoConfig]::Project.TokensPerClan) tokens" -ForegroundColor DarkGray
    Write-Host "       Mint Price:     " -NoNewline -ForegroundColor White
    Write-Host "$([BushidoConfig]::Project.MintPrice) ETH" -ForegroundColor DarkGray
    Write-Host "       Max/Wallet:     " -NoNewline -ForegroundColor White
    Write-Host "$([BushidoConfig]::Project.MaxPerWallet) NFTs" -ForegroundColor DarkGray
    Write-Host "       Blockchain:     " -NoNewline -ForegroundColor White
    Write-Host "$([BushidoConfig]::Project.Blockchain)" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-Clans {
    Write-Host "    🏯 The Eight Clans of Bushido:" -ForegroundColor Cyan
    
    [BushidoConfig]::Clans | ForEach-Object {
        $clan = $_
        Write-Host "       $($clan.Symbol) " -NoNewline
        Write-Host "$($clan.Name.PadRight(10))" -NoNewline -ForegroundColor White
        Write-Host "- $($clan.Virtue)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Show-Progress {
    param(
        [string]$Task,
        [string]$Status = "Working"
    )
    
    $spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $i = 0
    
    $job = Start-Job -ScriptBlock {
        Start-Sleep -Seconds 1
    }
    
    while ($job.State -eq 'Running') {
        Write-Host "`r    $($spinner[$i % $spinner.Length]) $Task... " -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 100
        $i++
    }
    
    Write-Host "`r    ✓ $Task    " -ForegroundColor Green
}

function Show-Success {
    param([hashtable]$Metrics)
    
    Write-Host "`n    ✨ " -NoNewline -ForegroundColor Magenta
    Write-Host "PROJECT SETUP COMPLETE!" -ForegroundColor White
    Write-Host "    ═══════════════════════════════════════════════════" -ForegroundColor DarkGreen
    
    if ($Metrics -and $Metrics.Count -gt 0) {
        Write-Host "`n    📊 Setup Metrics:" -ForegroundColor Yellow
        
        $total = 0
        foreach ($metric in $Metrics.GetEnumerator()) {
            if ($metric.Key -match "Level_(.+)") {
                $level = $Matches[1]
                $total += $metric.Value
                
                Write-Host "       $($level.PadRight(12))" -NoNewline -ForegroundColor White
                Write-Host "$($metric.Value) events" -ForegroundColor Green
            }
        }
        
        Write-Host "       $('Total'.PadRight(12))" -NoNewline -ForegroundColor White
        Write-Host "$total events" -ForegroundColor Cyan
    }
    
    Write-Host "`n    🚀 Next Steps:" -ForegroundColor Cyan
    Write-Host "       1. Install dependencies:    " -NoNewline -ForegroundColor White
    Write-Host "pnpm install" -ForegroundColor Yellow
    Write-Host "       2. Configure environment:   " -NoNewline -ForegroundColor White
    Write-Host "cp .env.example .env" -ForegroundColor Yellow
    Write-Host "       3. Deploy to testnet:       " -NoNewline -ForegroundColor White
    Write-Host "pnpm deploy:testnet" -ForegroundColor Yellow
    Write-Host "       4. Launch countdown:        " -NoNewline -ForegroundColor White
    Write-Host "pnpm launch:countdown" -ForegroundColor Yellow
    
    Write-Host "`n    🥷 Stealth Launch Commands:" -ForegroundColor Magenta
    Write-Host "       pnpm dev:stealth        " -NoNewline -ForegroundColor White
    Write-Host "# Run stealth countdown locally" -ForegroundColor DarkGray
    Write-Host "       pnpm deploy:mainnet     " -NoNewline -ForegroundColor White
    Write-Host "# Deploy to Abstract mainnet" -ForegroundColor DarkGray
    Write-Host "       pnpm launch:countdown   " -NoNewline -ForegroundColor White
    Write-Host "# Deploy countdown to Vercel`n" -ForegroundColor DarkGray
    
    Write-Host "    📖 Documentation:" -ForegroundColor Blue
    Write-Host "       README.md               " -NoNewline -ForegroundColor White
    Write-Host "# Project overview" -ForegroundColor DarkGray
    Write-Host "       .env.example            " -NoNewline -ForegroundColor White
    Write-Host "# Configuration template`n" -ForegroundColor DarkGray
}

function Show-Error {
    param([string]$Error)
    
    Write-Host "`n    ❌ Setup Failed" -ForegroundColor Red
    Write-Host "    ═══════════════════════════════════════════════════" -ForegroundColor DarkRed
    Write-Host "`n    Error: " -NoNewline -ForegroundColor White
    Write-Host $Error -ForegroundColor Yellow
    Write-Host "`n    💡 Troubleshooting:" -ForegroundColor Cyan
    Write-Host "       - Check prerequisites are installed correctly" -ForegroundColor White
    Write-Host "       - Ensure you have write permissions" -ForegroundColor White
    Write-Host "       - Review the log file in logs/bushido-setup.log" -ForegroundColor White
    Write-Host "       - Run with -OutputLevel Diagnostic for more details`n" -ForegroundColor White
}

# ═══════════════════════════════════════════════════════════════════
# Main Entry Point
# ═══════════════════════════════════════════════════════════════════

# Show banner
Show-Banner

# Show configuration
Show-Configuration
Show-Clans

# Initialize orchestrator
$orchestrator = $null

try {
    # Create orchestrator
    $orchestrator = [SetupOrchestrator]::new($ProjectPath, $OutputLevel)
    
    # Validate prerequisites if not skipped
    if (-not $SkipPrerequisites) {
        Write-Host "    🔍 Checking prerequisites..." -ForegroundColor Cyan
        
        $prereqResult = $orchestrator.ValidatePrerequisites()
        if (-not $prereqResult.Success) {
            Show-Error -Error $prereqResult.Error
            exit 1
        }
        
        Write-Host "    ✅ All prerequisites satisfied`n" -ForegroundColor Green
    }
    
    # Execute setup
    Write-Host "    🔨 Building project structure..." -ForegroundColor Cyan
    Write-Host ""
    
    $result = $orchestrator.Execute()
    
    if ($result.Success) {
        # Get metrics
        $metrics = $orchestrator.Logger.GetMetrics()
        
        # Show success
        Show-Success -Metrics $metrics
        
        # Show any warnings
        if ($result.Warnings.Count -gt 0) {
            Write-Host "    ⚠️  Warnings:" -ForegroundColor Yellow
            foreach ($warning in $result.Warnings) {
                Write-Host "       - $warning" -ForegroundColor Yellow
            }
            Write-Host ""
        }
    }
    else {
        Show-Error -Error $result.Error
        exit 1
    }
}
catch {
    Write-Host "`n    💥 Fatal Error" -ForegroundColor Red
    Write-Host "       $_" -ForegroundColor Yellow
    
    if ($OutputLevel -eq 'Diagnostic') {
        Write-Host "`n    Stack Trace:" -ForegroundColor DarkGray
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    
    exit 1
}
finally {
    # Cleanup
    $orchestrator?.Dispose()
}

# ═══════════════════════════════════════════════════════════════════
# Script Metadata
# ═══════════════════════════════════════════════════════════════════

<#
.SYNOPSIS
    Bushido NFT project setup script with stealth launch configuration

.DESCRIPTION
    Creates a complete monorepo structure for the Bushido NFT project,
    including smart contracts, frontend, backend, and deployment scripts.
    Optimized for stealth launch on Abstract L2.

.PARAMETER ProjectPath
    Path where the project should be created (default: current directory)

.PARAMETER SkipPrerequisites
    Skip checking for required tools (Node.js, pnpm, git)

.PARAMETER MinimalSetup
    Create minimal structure without full configuration

.PARAMETER OutputLevel
    Logging verbosity: Quiet, Normal, Detailed, or Diagnostic

.EXAMPLE
    .\Bushido-Ultimate-Setup.ps1

.EXAMPLE
    .\Bushido-Ultimate-Setup.ps1 -OutputLevel Detailed -SkipPrerequisites

.EXAMPLE
    .\Bushido-Ultimate-Setup.ps1 -ProjectPath "C:\Projects\bushido-nft" -MinimalSetup

.NOTES
    Author: Bushido Development Team
    Version: 1.0.0
    Requires: PowerShell 7.0+, Node.js 18+, pnpm 8+
#>