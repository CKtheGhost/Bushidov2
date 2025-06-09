# Bushido-Enhanced-Setup.ps1
# An architectural masterpiece for Bushido NFT project orchestration
# Demonstrates advanced PowerShell patterns with reactive programming and state machines

#Requires -Version 7.0
using namespace System.Management.Automation
using namespace System.Collections.Concurrent
using namespace System.Threading.Tasks
using namespace System.IO

# ═══════════════════════════════════════════════════════════════════
# Advanced State Machine for Project Setup
# ═══════════════════════════════════════════════════════════════════

enum SetupState {
    Uninitialized
    PrerequisiteCheck
    WorkspaceCreation
    ContractsSetup
    FrontendSetup
    BackendSetup
    ScriptsSetup
    DependencyInstallation
    PostConfiguration
    Completed
    Failed
}

enum SetupEvent {
    Start
    PrerequisitesValid
    PrerequisitesFailed
    WorkspaceReady
    ContractsReady
    FrontendReady
    BackendReady
    ScriptsReady
    DependenciesInstalled
    ConfigurationComplete
    Error
}

# Sophisticated state machine implementation
class SetupStateMachine {
    hidden [SetupState]$CurrentState = [SetupState]::Uninitialized
    hidden [hashtable]$StateTransitions
    hidden [hashtable]$StateHandlers
    hidden [System.Collections.Generic.List[object]]$EventLog
    hidden [ScriptBlock]$OnStateChange
    
    SetupStateMachine() {
        $this.EventLog = [System.Collections.Generic.List[object]]::new()
        $this.InitializeTransitions()
        $this.InitializeHandlers()
    }
    
    hidden [void] InitializeTransitions() {
        $this.StateTransitions = @{
            [SetupState]::Uninitialized = @{
                [SetupEvent]::Start = [SetupState]::PrerequisiteCheck
            }
            [SetupState]::PrerequisiteCheck = @{
                [SetupEvent]::PrerequisitesValid = [SetupState]::WorkspaceCreation
                [SetupEvent]::PrerequisitesFailed = [SetupState]::Failed
            }
            [SetupState]::WorkspaceCreation = @{
                [SetupEvent]::WorkspaceReady = [SetupState]::ContractsSetup
                [SetupEvent]::Error = [SetupState]::Failed
            }
            [SetupState]::ContractsSetup = @{
                [SetupEvent]::ContractsReady = [SetupState]::FrontendSetup
                [SetupEvent]::Error = [SetupState]::Failed
            }
            [SetupState]::FrontendSetup = @{
                [SetupEvent]::FrontendReady = [SetupState]::BackendSetup
                [SetupEvent]::Error = [SetupState]::Failed
            }
            [SetupState]::BackendSetup = @{
                [SetupEvent]::BackendReady = [SetupState]::ScriptsSetup
                [SetupEvent]::Error = [SetupState]::Failed
            }
            [SetupState]::ScriptsSetup = @{
                [SetupEvent]::ScriptsReady = [SetupState]::DependencyInstallation
                [SetupEvent]::Error = [SetupState]::Failed
            }
            [SetupState]::DependencyInstallation = @{
                [SetupEvent]::DependenciesInstalled = [SetupState]::PostConfiguration
                [SetupEvent]::Error = [SetupState]::Failed
            }
            [SetupState]::PostConfiguration = @{
                [SetupEvent]::ConfigurationComplete = [SetupState]::Completed
                [SetupEvent]::Error = [SetupState]::Failed
            }
        }
    }
    
    hidden [void] InitializeHandlers() {
        $this.StateHandlers = @{}
    }
    
    [void] RegisterHandler([SetupState]$state, [ScriptBlock]$handler) {
        $this.StateHandlers[$state] = $handler
    }
    
    [void] RegisterStateChangeCallback([ScriptBlock]$callback) {
        $this.OnStateChange = $callback
    }
    
    [SetupState] ProcessEvent([SetupEvent]$event, [hashtable]$context = @{}) {
        $transition = $this.StateTransitions[$this.CurrentState][$event]
        
        if ($null -eq $transition) {
            throw "Invalid transition: $($this.CurrentState) -> $event"
        }
        
        $previousState = $this.CurrentState
        $this.CurrentState = $transition
        
        # Log state transition
        $this.EventLog.Add(@{
            Timestamp = [DateTime]::UtcNow
            PreviousState = $previousState
            Event = $event
            NewState = $this.CurrentState
            Context = $context
        })
        
        # Execute state change callback
        if ($this.OnStateChange) {
            & $this.OnStateChange $previousState $this.CurrentState $event $context
        }
        
        # Execute state handler if registered
        if ($this.StateHandlers.ContainsKey($this.CurrentState)) {
            & $this.StateHandlers[$this.CurrentState] $context
        }
        
        return $this.CurrentState
    }
    
    [SetupState] GetCurrentState() {
        return $this.CurrentState
    }
    
    [object[]] GetEventLog() {
        return $this.EventLog.ToArray()
    }
}

# ═══════════════════════════════════════════════════════════════════
# Advanced Logger with Event Sourcing
# ═══════════════════════════════════════════════════════════════════

class EventSourcedLogger {
    hidden [ConcurrentQueue[object]]$EventStream
    hidden [string]$LogPath
    hidden [System.Threading.Timer]$PersistenceTimer
    hidden [hashtable]$Metrics
    hidden [System.Threading.ReaderWriterLockSlim]$MetricsLock
    
    EventSourcedLogger([string]$projectPath) {
        $this.EventStream = [ConcurrentQueue[object]]::new()
        $this.LogPath = Join-Path $projectPath "logs" "setup-events.json"
        $this.Metrics = @{}
        $this.MetricsLock = [System.Threading.ReaderWriterLockSlim]::new()
        $this.InitializeLogDirectory()
        $this.InitializePersistence()
    }
    
    hidden [void] InitializeLogDirectory() {
        $logDir = Split-Path $this.LogPath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
    }
    
    hidden [void] InitializePersistence() {
        $callback = {
            $this.PersistEvents()
        }.GetNewClosure()
        
        $this.PersistenceTimer = [System.Threading.Timer]::new(
            $callback,
            $null,
            [TimeSpan]::FromSeconds(5),
            [TimeSpan]::FromSeconds(5)
        )
    }
    
    [void] LogEvent([string]$eventType, [hashtable]$data = @{}, [string]$level = "Info") {
        $event = @{
            Id = [Guid]::NewGuid().ToString()
            Timestamp = [DateTime]::UtcNow.ToString("o")
            Type = $eventType
            Level = $level
            Data = $data
            ProcessId = $PID
            MachineName = $env:COMPUTERNAME
        }
        
        $this.EventStream.Enqueue($event)
        $this.UpdateMetrics($eventType, $level)
        $this.WriteToConsole($event)
    }
    
    hidden [void] UpdateMetrics([string]$eventType, [string]$level) {
        $this.MetricsLock.EnterWriteLock()
        try {
            # Update event type counter
            $typeKey = "EventType_$eventType"
            if ($this.Metrics.ContainsKey($typeKey)) {
                $this.Metrics[$typeKey]++
            } else {
                $this.Metrics[$typeKey] = 1
            }
            
            # Update level counter
            $levelKey = "Level_$level"
            if ($this.Metrics.ContainsKey($levelKey)) {
                $this.Metrics[$levelKey]++
            } else {
                $this.Metrics[$levelKey] = 1
            }
        }
        finally {
            $this.MetricsLock.ExitWriteLock()
        }
    }
    
    hidden [void] WriteToConsole([hashtable]$event) {
        $colors = @{
            "Debug" = "DarkGray"
            "Info" = "Cyan"
            "Success" = "Green"
            "Warning" = "Yellow"
            "Error" = "Red"
            "Critical" = "DarkRed"
        }
        
        $symbols = @{
            "Debug" = "🔍"
            "Info" = "ℹ️"
            "Success" = "✅"
            "Warning" = "⚠️"
            "Error" = "❌"
            "Critical" = "🚨"
        }
        
        $timestamp = [DateTime]::Parse($event.Timestamp).ToLocalTime().ToString("HH:mm:ss")
        $color = $colors[$event.Level] ?? "White"
        $symbol = $symbols[$event.Level] ?? "•"
        
        Write-Host "[$timestamp] " -NoNewline -ForegroundColor DarkGray
        Write-Host "$symbol " -NoNewline
        Write-Host "$($event.Type): " -NoNewline -ForegroundColor $color
        
        if ($event.Data.Message) {
            Write-Host $event.Data.Message
        } else {
            Write-Host "Event processed"
        }
    }
    
    [void] PersistEvents() {
        $events = @()
        $event = $null
        
        while ($this.EventStream.TryDequeue([ref]$event)) {
            $events += $event
        }
        
        if ($events.Count -gt 0) {
            $existingContent = @()
            if (Test-Path $this.LogPath) {
                $existingContent = Get-Content $this.LogPath -Raw | ConvertFrom-Json
            }
            
            $allEvents = $existingContent + $events
            $allEvents | ConvertTo-Json -Depth 10 | Set-Content $this.LogPath -Encoding UTF8
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
        $this.PersistenceTimer?.Dispose()
        $this.PersistEvents()
        $this.MetricsLock?.Dispose()
    }
}

# ═══════════════════════════════════════════════════════════════════
# Dependency Injection Container
# ═══════════════════════════════════════════════════════════════════

class ServiceContainer {
    hidden [hashtable]$Services = @{}
    hidden [hashtable]$Factories = @{}
    hidden [System.Threading.ReaderWriterLockSlim]$Lock
    
    ServiceContainer() {
        $this.Lock = [System.Threading.ReaderWriterLockSlim]::new()
    }
    
    [void] RegisterSingleton([string]$name, [object]$instance) {
        $this.Lock.EnterWriteLock()
        try {
            $this.Services[$name] = $instance
        }
        finally {
            $this.Lock.ExitWriteLock()
        }
    }
    
    [void] RegisterFactory([string]$name, [ScriptBlock]$factory) {
        $this.Lock.EnterWriteLock()
        try {
            $this.Factories[$name] = $factory
        }
        finally {
            $this.Lock.ExitWriteLock()
        }
    }
    
    [object] Resolve([string]$name) {
        $this.Lock.EnterReadLock()
        try {
            if ($this.Services.ContainsKey($name)) {
                return $this.Services[$name]
            }
            
            if ($this.Factories.ContainsKey($name)) {
                $this.Lock.ExitReadLock()
                $this.Lock.EnterWriteLock()
                try {
                    # Double-check pattern
                    if ($this.Services.ContainsKey($name)) {
                        return $this.Services[$name]
                    }
                    
                    $instance = & $this.Factories[$name]
                    $this.Services[$name] = $instance
                    return $instance
                }
                finally {
                    $this.Lock.ExitWriteLock()
                    $this.Lock.EnterReadLock()
                }
            }
            
            throw "Service '$name' not registered"
        }
        finally {
            $this.Lock.ExitReadLock()
        }
    }
    
    [void] Dispose() {
        $this.Lock?.Dispose()
    }
}

# ═══════════════════════════════════════════════════════════════════
# Project Builder with Advanced Patterns
# ═══════════════════════════════════════════════════════════════════

class BushidoProjectBuilder {
    hidden [ServiceContainer]$Container
    hidden [EventSourcedLogger]$Logger
    hidden [SetupStateMachine]$StateMachine
    hidden [hashtable]$Configuration
    hidden [System.Collections.Generic.Stack[ScriptBlock]]$CompensationStack
    
    BushidoProjectBuilder([ServiceContainer]$container) {
        $this.Container = $container
        $this.Logger = $container.Resolve("Logger")
        $this.StateMachine = $container.Resolve("StateMachine")
        $this.Configuration = $container.Resolve("Configuration")
        $this.CompensationStack = [System.Collections.Generic.Stack[ScriptBlock]]::new()
        $this.RegisterStateHandlers()
    }
    
    hidden [void] RegisterStateHandlers() {
        # Workspace Creation Handler
        $this.StateMachine.RegisterHandler([SetupState]::WorkspaceCreation, {
            param($context)
            $this.CreateWorkspaceStructure()
            $this.StateMachine.ProcessEvent([SetupEvent]::WorkspaceReady)
        }.GetNewClosure())
        
        # Contracts Setup Handler
        $this.StateMachine.RegisterHandler([SetupState]::ContractsSetup, {
            param($context)
            $this.SetupContracts()
            $this.StateMachine.ProcessEvent([SetupEvent]::ContractsReady)
        }.GetNewClosure())
        
        # Frontend Setup Handler
        $this.StateMachine.RegisterHandler([SetupState]::FrontendSetup, {
            param($context)
            $this.SetupFrontend()
            $this.StateMachine.ProcessEvent([SetupEvent]::FrontendReady)
        }.GetNewClosure())
        
        # Backend Setup Handler
        $this.StateMachine.RegisterHandler([SetupState]::BackendSetup, {
            param($context)
            $this.SetupBackend()
            $this.StateMachine.ProcessEvent([SetupEvent]::BackendReady)
        }.GetNewClosure())
        
        # Scripts Setup Handler
        $this.StateMachine.RegisterHandler([SetupState]::ScriptsSetup, {
            param($context)
            $this.SetupScripts()
            $this.StateMachine.ProcessEvent([SetupEvent]::ScriptsReady)
        }.GetNewClosure())
    }
    
    [void] Build() {
        try {
            $this.StateMachine.ProcessEvent([SetupEvent]::Start)
            
            # Check prerequisites
            if ($this.CheckPrerequisites()) {
                $this.StateMachine.ProcessEvent([SetupEvent]::PrerequisitesValid)
            } else {
                $this.StateMachine.ProcessEvent([SetupEvent]::PrerequisitesFailed)
                return
            }
            
            # The state machine will handle the rest through its handlers
            
        } catch {
            $this.Logger.LogEvent("BuildError", @{
                Message = $_.Exception.Message
                StackTrace = $_.ScriptStackTrace
            }, "Error")
            
            $this.ExecuteCompensation()
            $this.StateMachine.ProcessEvent([SetupEvent]::Error)
            throw
        }
    }
    
    hidden [bool] CheckPrerequisites() {
        $this.Logger.LogEvent("PrerequisiteCheck", @{ Message = "Checking system prerequisites" })
        
        $prerequisites = @{
            "node" = @{ MinVersion = "18.0.0"; Command = "node --version" }
            "pnpm" = @{ MinVersion = "8.0.0"; Command = "pnpm --version" }
            "git" = @{ MinVersion = "2.0.0"; Command = "git --version" }
        }
        
        $allValid = $true
        
        foreach ($tool in $prerequisites.GetEnumerator()) {
            $result = $this.CheckTool($tool.Key, $tool.Value)
            if (-not $result) {
                $allValid = $false
            }
        }
        
        return $allValid
    }
    
    hidden [bool] CheckTool([string]$name, [hashtable]$config) {
        try {
            $output = Invoke-Expression $config.Command 2>&1
            $this.Logger.LogEvent("ToolCheck", @{
                Tool = $name
                Version = $output
                Status = "Found"
            }, "Success")
            return $true
        } catch {
            $this.Logger.LogEvent("ToolCheck", @{
                Tool = $name
                Status = "NotFound"
                Error = $_.Exception.Message
            }, "Error")
            return $false
        }
    }
    
    hidden [void] CreateWorkspaceStructure() {
        $this.Logger.LogEvent("WorkspaceCreation", @{ Message = "Creating monorepo structure" })
        
        $this.ExecuteWithCompensation(
            {
                # Root package.json with sophisticated configuration
                $rootPackage = @{
                    name = "bushido-nft"
                    version = "1.0.0"
                    private = $true
                    type = "module"
                    engines = @{
                        node = ">=18.0.0"
                        pnpm = ">=8.0.0"
                    }
                    scripts = @{
                        # Development
                        "dev" = "turbo run dev --parallel --continue"
                        "dev:contracts" = "turbo run dev --filter=@bushido/contracts"
                        "dev:frontend" = "turbo run dev --filter=@bushido/frontend"
                        "dev:backend" = "turbo run dev --filter=@bushido/backend"
                        
                        # Building
                        "build" = "turbo run build"
                        "build:contracts" = "turbo run build --filter=@bushido/contracts"
                        "build:production" = "turbo run build --filter='!@bushido/scripts'"
                        
                        # Testing
                        "test" = "turbo run test"
                        "test:unit" = "turbo run test:unit"
                        "test:integration" = "turbo run test:integration"
                        "test:e2e" = "playwright test"
                        
                        # Deployment
                        "deploy:testnet" = "turbo run deploy --filter=@bushido/contracts -- --network abstract-testnet"
                        "deploy:mainnet" = "turbo run deploy --filter=@bushido/contracts -- --network abstract"
                        
                        # Quality
                        "lint" = "turbo run lint"
                        "format" = "prettier --write '**/*.{js,jsx,ts,tsx,json,sol,md}'"
                        "typecheck" = "turbo run typecheck"
                        
                        # Utilities
                        "clean" = "turbo run clean && rimraf node_modules .turbo"
                        "changeset" = "changeset"
                        "version" = "changeset version"
                        "release" = "turbo run build && changeset publish"
                    }
                    devDependencies = @{
                        "turbo" = "latest"
                        "prettier" = "^3.2.5"
                        "eslint" = "^8.56.0"
                        "@changesets/cli" = "^2.27.1"
                        "rimraf" = "^5.0.5"
                        "husky" = "^9.0.10"
                        "lint-staged" = "^15.2.0"
                        "@playwright/test" = "^1.41.0"
                    }
                    packageManager = "pnpm@8.15.1"
                }
                
                $this.WriteJsonFile("package.json", $rootPackage)
                
                # Workspace configuration
                $workspaceYaml = @"
packages:
  - 'contracts'
  - 'frontend'
  - 'backend'
  - 'scripts'

catalog:
  '@openzeppelin/contracts': ^5.0.1
  'typescript': ^5.3.3
  'ethers': ^6.10.0
"@
                $this.WriteFile("pnpm-workspace.yaml", $workspaceYaml)
                
                # Turbo configuration with remote caching
                $turboConfig = @{
                    '$schema' = "https://turbo.build/schema.json"
                    globalDependencies = @(".env", ".env.local")
                    pipeline = @{
                        build = @{
                            dependsOn = @("^build")
                            outputs = @("dist/**", ".next/**", "artifacts/**", "typechain-types/**")
                            env = @("NODE_ENV")
                        }
                        test = @{
                            dependsOn = @("build")
                            outputs = @("coverage/**")
                            cache = $false
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
                            env = @("PRIVATE_KEY", "NETWORK")
                        }
                        typecheck = @{
                            dependsOn = @("^build")
                            outputs = @()
                        }
                    }
                }
                
                $this.WriteJsonFile("turbo.json", $turboConfig)
                
                $this.Logger.LogEvent("WorkspaceStructureCreated", @{
                    Files = @("package.json", "pnpm-workspace.yaml", "turbo.json")
                }, "Success")
            },
            {
                # Compensation
                @("package.json", "pnpm-workspace.yaml", "turbo.json") | ForEach-Object {
                    Remove-Item $_ -Force -ErrorAction SilentlyContinue
                }
            }
        )
    }
    
    hidden [void] SetupContracts() {
        $this.Logger.LogEvent("ContractsSetup", @{ Message = "Initializing smart contracts package" })
        
        $contractsPath = "contracts"
        
        $this.ExecuteWithCompensation(
            {
                New-Item -ItemType Directory -Path $contractsPath -Force | Out-Null
                
                Push-Location $contractsPath
                try {
                    # Sophisticated package.json for contracts
                    $packageJson = @{
                        name = "@bushido/contracts"
                        version = "1.0.0"
                        private = $true
                        type = "module"
                        scripts = @{
                            "compile" = "hardhat compile"
                            "clean" = "hardhat clean && rimraf artifacts cache typechain-types coverage"
                            "test" = "hardhat test"
                            "test:coverage" = "hardhat coverage"
                            "test:gas" = "REPORT_GAS=true hardhat test"
                            "deploy" = "hardhat run scripts/deploy.ts"
                            "verify" = "hardhat verify"
                            "typechain" = "hardhat typechain"
                            "size" = "hardhat size-contracts"
                            "audit" = "slither ."
                            "lint" = "solhint 'contracts/**/*.sol'"
                            "format" = "prettier --write 'contracts/**/*.sol'"
                        }
                        devDependencies = @{
                            "hardhat" = "^2.19.4"
                            "@nomicfoundation/hardhat-toolbox" = "^4.0.0"
                            "@nomicfoundation/hardhat-verify" = "^2.0.3"
                            "@openzeppelin/contracts" = "^5.0.1"
                            "@openzeppelin/contracts-upgradeable" = "^5.0.1"
                            "@openzeppelin/hardhat-upgrades" = "^3.0.2"
                            "hardhat-contract-sizer" = "^2.10.0"
                            "hardhat-gas-reporter" = "^1.0.9"
                            "solidity-coverage" = "^0.8.5"
                            "@typechain/hardhat" = "^9.1.0"
                            "@typechain/ethers-v6" = "^0.5.1"
                            "typescript" = "^5.3.3"
                            "ts-node" = "^10.9.2"
                            "dotenv" = "^16.3.1"
                            "solhint" = "^4.1.1"
                        }
                    }
                    
                    $this.WriteJsonFile("package.json", $packageJson)
                    
                    # Create sophisticated directory structure
                    @(
                        "contracts",
                        "contracts/interfaces",
                        "contracts/libraries",
                        "contracts/mocks",
                        "scripts",
                        "test",
                        "test/unit",
                        "test/integration"
                    ) | ForEach-Object {
                        New-Item -ItemType Directory -Path $_ -Force | Out-Null
                    }
                    
                    # Create the main NFT contract
                    $this.CreateBushidoNFTContract()
                    
                    # Create Hardhat configuration
                    $this.CreateHardhatConfig()
                    
                    $this.Logger.LogEvent("ContractsPackageCreated", @{
                        Path = $contractsPath
                    }, "Success")
                }
                finally {
                    Pop-Location
                }
            },
            {
                Remove-Item $contractsPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        )
    }
    
    hidden [void] CreateBushidoNFTContract() {
        $contractContent = @'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IBushidoNFT.sol";
import "./libraries/VotingMechanics.sol";

/**
 * @title BushidoNFT
 * @author Bushido Development Team
 * @notice Interactive NFT with integrated voting mechanics for episodic storytelling
 * @dev Implements advanced patterns including role-based access, pausability, and upgradeable voting
 */
contract BushidoNFT is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Pausable,
    AccessControl,
    ReentrancyGuard,
    IBushidoNFT
{
    using Counters for Counters.Counter;
    using VotingMechanics for uint256;
    
    // ═══════════════════════════════════════════════════════════════════
    // Constants and Immutables
    // ═══════════════════════════════════════════════════════════════════
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant EPISODE_MANAGER_ROLE = keccak256("EPISODE_MANAGER_ROLE");
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    
    uint256 public constant MAX_SUPPLY = 1600;
    uint256 public constant TOKENS_PER_CLAN = 200;
    uint256 public constant MINT_PRICE = 0.08 ether;
    uint256 public constant MAX_PER_WALLET = 3;
    uint256 public constant CLAN_COUNT = 8;
    
    // Clan identifiers
    enum Clan {
        Dragon,    // Courage
        Phoenix,   // Rebirth
        Tiger,     // Strength
        Serpent,   // Wisdom
        Eagle,     // Vision
        Wolf,      // Loyalty
        Bear,      // Protection
        Lion       // Leadership
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // State Variables
    // ═══════════════════════════════════════════════════════════════════
    
    Counters.Counter private _tokenIdCounter;
    
    mapping(uint256 => TokenMetadata) private _tokenMetadata;
    mapping(uint256 => uint256) public tokenVotingPower;
    mapping(address => uint256) public mintedPerWallet;
    mapping(uint256 => mapping(uint256 => bool)) public hasVotedInEpisode;
    mapping(uint256 => mapping(uint256 => uint256)) public episodeVotes;
    mapping(uint256 => uint256) public episodeDeadlines;
    
    string private _baseTokenURI;
    uint256 public currentEpisode;
    bool public mintActive;
    bytes32 public merkleRoot;
    
    // ═══════════════════════════════════════════════════════════════════
    // Events
    // ═══════════════════════════════════════════════════════════════════
    
    event MintActivated(uint256 timestamp, address activator);
    event TokenMinted(
        address indexed to,
        uint256 indexed tokenId,
        uint256 clan,
        uint256 rarity,
        uint256 votingPower
    );
    event VoteCast(
        uint256 indexed tokenId,
        uint256 indexed episodeId,
        uint256 choice,
        uint256 votingPower,
        address voter
    );
    event EpisodeAdvanced(uint256 newEpisode, uint256 deadline);
    event BaseURIUpdated(string newURI);
    event FundsWithdrawn(address indexed to, uint256 amount);
    
    // ═══════════════════════════════════════════════════════════════════
    // Constructor
    // ═══════════════════════════════════════════════════════════════════
    
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseURI;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(EPISODE_MANAGER_ROLE, msg.sender);
        _grantRole(TREASURY_ROLE, msg.sender);
        
        currentEpisode = 1;
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // Minting Functions
    // ═══════════════════════════════════════════════════════════════════
    
    function activateMint() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!mintActive, "Mint already active");
        mintActive = true;
        emit MintActivated(block.timestamp, msg.sender);
    }
    
    function mint(uint256 quantity)
        external
        payable
        nonReentrant
        whenNotPaused
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
            
            // Determine clan based on token ID
            uint256 clanId = ((tokenId - 1) / TOKENS_PER_CLAN);
            require(clanId < CLAN_COUNT, "Invalid clan assignment");
            
            // Generate rarity with sophisticated randomness
            uint256 rarity = _generateRarity(tokenId, msg.sender);
            
            // Create token metadata
            _tokenMetadata[tokenId] = TokenMetadata({
                clan: Clan(clanId),
                rarity: rarity,
                generation: 1,
                evolutionStage: 0,
                lastVotedEpisode: 0
            });
            
            // Calculate voting power using library
            tokenVotingPower[tokenId] = rarity.calculateVotingPower();
            
            // Mint token
            _safeMint(msg.sender, tokenId);
            
            emit TokenMinted(
                msg.sender,
                tokenId,
                clanId,
                rarity,
                tokenVotingPower[tokenId]
            );
        }
        
        mintedPerWallet[msg.sender] += quantity;
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // Voting System
    // ═══════════════════════════════════════════════════════════════════
    
    function castVote(uint256 tokenId, uint256 choice)
        external
        nonReentrant
        whenNotPaused
    {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        require(!hasVotedInEpisode[tokenId][currentEpisode], "Already voted");
        require(choice > 0 && choice <= 4, "Invalid choice");
        require(
            block.timestamp < episodeDeadlines[currentEpisode],
            "Voting closed"
        );
        
        hasVotedInEpisode[tokenId][currentEpisode] = true;
        _tokenMetadata[tokenId].lastVotedEpisode = currentEpisode;
        
        uint256 votePower = tokenVotingPower[tokenId];
        episodeVotes[currentEpisode][choice] += votePower;
        
        emit VoteCast(
            tokenId,
            currentEpisode,
            choice,
            votePower,
            msg.sender
        );
    }
    
    function advanceEpisode(uint256 deadline)
        external
        onlyRole(EPISODE_MANAGER_ROLE)
    {
        require(deadline > block.timestamp, "Invalid deadline");
        currentEpisode++;
        episodeDeadlines[currentEpisode] = deadline;
        emit EpisodeAdvanced(currentEpisode, deadline);
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // View Functions
    // ═══════════════════════════════════════════════════════════════════
    
    function getTokenMetadata(uint256 tokenId)
        external
        view
        returns (TokenMetadata memory)
    {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return _tokenMetadata[tokenId];
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
    
    function getEpisodeResults(uint256 episode)
        external
        view
        returns (uint256[5] memory results)
    {
        for (uint256 i = 1; i <= 4; i++) {
            results[i] = episodeVotes[episode][i];
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // Admin Functions
    // ═══════════════════════════════════════════════════════════════════
    
    function setBaseURI(string memory newURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseTokenURI = newURI;
        emit BaseURIUpdated(newURI);
    }
    
    function withdraw()
        external
        onlyRole(TREASURY_ROLE)
        nonReentrant
    {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Withdrawal failed");
        
        emit FundsWithdrawn(msg.sender, balance);
    }
    
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }
    
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // Internal Functions
    // ═══════════════════════════════════════════════════════════════════
    
    function _generateRarity(uint256 tokenId, address minter)
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
                    minter,
                    _tokenIdCounter.current()
                )
            )
        );
        
        uint256 rand = seed % 10000; // 0-9999 for precision
        
        if (rand < 100) return 5;    // Legendary (1%)
        if (rand < 500) return 4;    // Epic (4%)
        if (rand < 1500) return 3;   // Rare (10%)
        if (rand < 3500) return 2;   // Uncommon (20%)
        return 1;                     // Common (65%)
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // Override Functions
    // ═══════════════════════════════════════════════════════════════════
    
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable, ERC721Pausable) returns (address) {
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
        
        $this.WriteFile("contracts/BushidoNFT.sol", $contractContent)
        
        # Create interface
        $interfaceContent = @'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBushidoNFT {
    enum Clan {
        Dragon,
        Phoenix,
        Tiger,
        Serpent,
        Eagle,
        Wolf,
        Bear,
        Lion
    }
    
    struct TokenMetadata {
        Clan clan;
        uint256 rarity;
        uint256 generation;
        uint256 evolutionStage;
        uint256 lastVotedEpisode;
    }
    
    function castVote(uint256 tokenId, uint256 choice) external;
    function getTokenMetadata(uint256 tokenId) external view returns (TokenMetadata memory);
    function getTotalVotingPower(address wallet) external view returns (uint256);
}
'@
        
        $this.WriteFile("contracts/interfaces/IBushidoNFT.sol", $interfaceContent)
        
        # Create voting library
        $libraryContent = @'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library VotingMechanics {
    /**
     * @dev Calculate voting power based on rarity
     * Uses exponential scaling for rarity influence
     */
    function calculateVotingPower(uint256 rarity) internal pure returns (uint256) {
        // Base power + rarity bonus
        uint256 basePower = 1;
        uint256 rarityMultiplier = rarity ** 2;
        return basePower * rarityMultiplier;
    }
    
    /**
     * @dev Calculate clan bonus for special events
     */
    function calculateClanBonus(uint256 clanId, uint256 episodeTheme) internal pure returns (uint256) {
        // Special clan advantages for themed episodes
        if (clanId == episodeTheme) {
            return 2; // 2x multiplier
        }
        return 1;
    }
}
'@
        
        $this.WriteFile("contracts/libraries/VotingMechanics.sol", $libraryContent)
    }
    
    hidden [void] CreateHardhatConfig() {
        $configContent = @'
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import * as dotenv from "dotenv";

dotenv.config({ path: "../.env" });

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
      url: process.env.ABSTRACT_TESTNET_RPC || "https://api.testnet.abs.xyz",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11124,
      gasPrice: "auto"
    },
    abstract: {
      url: process.env.ABSTRACT_MAINNET_RPC || "https://api.abs.xyz",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11125,
      gasPrice: "auto"
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    currency: "USD",
    gasPrice: 20,
    token: "ETH",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY
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
  }
};

export default config;
'@
        
        $this.WriteFile("hardhat.config.ts", $configContent)
        
        # Create TypeScript config
        $tsConfig = @{
            compilerOptions = @{
                target = "es2020"
                module = "commonjs"
                lib = @("es2020")
                outDir = "./dist"
                rootDir = "./src"
                strict = $true
                esModuleInterop = $true
                skipLibCheck = $true
                forceConsistentCasingInFileNames = $true
                resolveJsonModule = $true
                noImplicitAny = $true
                noUnusedLocals = $true
                noUnusedParameters = $true
            }
            include = @("./scripts", "./test", "./hardhat.config.ts")
            exclude = @("node_modules", "dist")
        }
        
        $this.WriteJsonFile("tsconfig.json", $tsConfig)
    }
    
    hidden [void] SetupFrontend() {
        $this.Logger.LogEvent("FrontendSetup", @{ Message = "Creating Next.js frontend application" })
        
        $frontendPath = "frontend"
        
        $this.ExecuteWithCompensation(
            {
                # Create Next.js app with specific configuration
                $this.Logger.LogEvent("NextJsCreation", @{ Message = "Initializing Next.js with TypeScript and Tailwind" })
                
                # For minimal setup, just create structure
                if ($this.Configuration.MinimalSetup) {
                    New-Item -ItemType Directory -Path $frontendPath -Force | Out-Null
                    Push-Location $frontendPath
                    try {
                        $this.CreateMinimalFrontendStructure()
                    } finally {
                        Pop-Location
                    }
                } else {
                    # Full Next.js creation
                    $createProcess = Start-Process -FilePath "pnpm" -ArgumentList @(
                        "create", "next-app@latest", $frontendPath,
                        "--typescript", "--tailwind", "--app",
                        "--src-dir", "--import-alias", "@/*",
                        "--no-git", "--yes"
                    ) -NoNewWindow -Wait -PassThru
                    
                    if ($createProcess.ExitCode -eq 0) {
                        Push-Location $frontendPath
                        try {
                            $this.EnhanceFrontendPackage()
                            $this.CreateFrontendStructure()
                        } finally {
                            Pop-Location
                        }
                    } else {
                        throw "Failed to create Next.js application"
                    }
                }
                
                $this.Logger.LogEvent("FrontendSetupComplete", @{
                    Path = $frontendPath
                }, "Success")
            },
            {
                Remove-Item $frontendPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        )
    }
    
    hidden [void] CreateMinimalFrontendStructure() {
        # Minimal package.json
        $packageJson = @{
            name = "@bushido/frontend"
            version = "1.0.0"
            private = $true
            scripts = @{
                "dev" = "next dev"
                "build" = "next build"
                "start" = "next start"
                "lint" = "next lint"
                "typecheck" = "tsc --noEmit"
            }
            dependencies = @{
                "next" = "14.1.0"
                "react" = "^18.2.0"
                "react-dom" = "^18.2.0"
            }
            devDependencies = @{
                "@types/node" = "^20.11.0"
                "@types/react" = "^18.2.48"
                "@types/react-dom" = "^18.2.18"
                "typescript" = "^5.3.3"
                "tailwindcss" = "^3.4.1"
                "autoprefixer" = "^10.4.17"
                "postcss" = "^8.4.33"
            }
        }
        
        $this.WriteJsonFile("package.json", $packageJson)
        
        # Create basic structure
        @("src", "src/app", "src/components", "src/lib", "public") | ForEach-Object {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }
    
    hidden [void] EnhanceFrontendPackage() {
        # Read existing package.json
        $packagePath = "package.json"
        $package = Get-Content $packagePath -Raw | ConvertFrom-Json
        
        # Add Web3 and animation dependencies
        $additionalDeps = @{
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
            
            # UI components
            "lucide-react" = "^0.312.0"
            "@radix-ui/react-dialog" = "^1.0.5"
            "@radix-ui/react-tabs" = "^1.0.4"
            "@radix-ui/react-tooltip" = "^1.0.7"
            
            # State management
            "zustand" = "^4.4.7"
            "@tanstack/react-query" = "^5.17.9"
            
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
        
        # Add development dependencies
        $additionalDevDeps = @{
            "@typescript-eslint/eslint-plugin" = "^6.19.0"
            "@typescript-eslint/parser" = "^6.19.0"
            "eslint-config-prettier" = "^9.1.0"
            "prettier-plugin-tailwindcss" = "^0.5.11"
        }
        
        foreach ($dep in $additionalDevDeps.GetEnumerator()) {
            if (-not $package.devDependencies.PSObject.Properties[$dep.Key]) {
                $package.devDependencies | Add-Member -MemberType NoteProperty -Name $dep.Key -Value $dep.Value -Force
            }
        }
        
        # Update scripts
        $package.scripts | Add-Member -MemberType NoteProperty -Name "analyze" -Value "ANALYZE=true next build" -Force
        $package.scripts | Add-Member -MemberType NoteProperty -Name "typecheck" -Value "tsc --noEmit" -Force
        
        $this.WriteJsonFile($packagePath, $package)
    }
    
    hidden [void] CreateFrontendStructure() {
        # Create sophisticated directory structure
        $directories = @(
            "src/components/countdown",
            "src/components/mint",
            "src/components/episodes",
            "src/components/voting",
            "src/components/three",
            "src/components/ui",
            "src/components/layout",
            "src/hooks",
            "src/lib/web3",
            "src/lib/api",
            "src/lib/state",
            "src/lib/utils",
            "src/types",
            "src/styles",
            "public/videos",
            "public/models",
            "public/images/clans",
            "public/fonts"
        )
        
        $directories | ForEach-Object {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
        
        # Create Web3 configuration
        $this.CreateWeb3Config()
        
        # Create state management
        $this.CreateStateManagement()
        
        # Create utility functions
        $this.CreateUtilities()
        
        # Create TypeScript types
        $this.CreateTypes()
    }
    
    hidden [void] CreateWeb3Config() {
        $wagmiConfig = @'
'use client';

import { createConfig, configureChains } from 'wagmi';
import { abstractTestnet, abstract } from 'wagmi/chains';
import { alchemyProvider } from 'wagmi/providers/alchemy';
import { publicProvider } from 'wagmi/providers/public';
import { getDefaultWallets } from '@rainbow-me/rainbowkit';

// Define Abstract chains
const abstractMainnet = {
  id: 11125,
  name: 'Abstract',
  network: 'abstract',
  nativeCurrency: {
    decimals: 18,
    name: 'Ethereum',
    symbol: 'ETH',
  },
  rpcUrls: {
    default: { http: ['https://api.abs.xyz'] },
    public: { http: ['https://api.abs.xyz'] },
  },
  blockExplorers: {
    default: { name: 'Abstract Explorer', url: 'https://explorer.abs.xyz' },
  },
};

const abstractTestnetChain = {
  id: 11124,
  name: 'Abstract Testnet',
  network: 'abstract-testnet',
  nativeCurrency: {
    decimals: 18,
    name: 'Ethereum',
    symbol: 'ETH',
  },
  rpcUrls: {
    default: { http: ['https://api.testnet.abs.xyz'] },
    public: { http: ['https://api.testnet.abs.xyz'] },
  },
  blockExplorers: {
    default: { name: 'Abstract Explorer', url: 'https://explorer.testnet.abs.xyz' },
  },
  testnet: true,
};

const { chains, publicClient, webSocketPublicClient } = configureChains(
  [
    process.env.NEXT_PUBLIC_NETWORK === 'mainnet' ? abstractMainnet : abstractTestnetChain
  ],
  [
    ...(process.env.NEXT_PUBLIC_ALCHEMY_KEY 
      ? [alchemyProvider({ apiKey: process.env.NEXT_PUBLIC_ALCHEMY_KEY })]
      : []),
    publicProvider()
  ]
);

const { connectors } = getDefaultWallets({
  appName: 'Bushido NFT',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || '',
  chains,
});

export const wagmiConfig = createConfig({
  autoConnect: true,
  connectors,
  publicClient,
  webSocketPublicClient,
});

export { chains };
'@
        
        $this.WriteFile("src/lib/web3/config.ts", $wagmiConfig)
        
        # Create contract configuration
        $contractConfig = @'
export const CONTRACTS = {
  BushidoNFT: {
    address: process.env.NEXT_PUBLIC_CONTRACT_ADDRESS as `0x${string}`,
    abi: [] as const, // Will be populated after deployment
  },
} as const;

export const MINT_CONFIG = {
  price: 0.08,
  maxPerWallet: 3,
  maxSupply: 1600,
} as const;

export const CLANS = [
  { id: 0, name: 'Dragon', virtue: 'Courage', color: '#DC2626' },
  { id: 1, name: 'Phoenix', virtue: 'Rebirth', color: '#F59E0B' },
  { id: 2, name: 'Tiger', virtue: 'Strength', color: '#F97316' },
  { id: 3, name: 'Serpent', virtue: 'Wisdom', color: '#8B5CF6' },
  { id: 4, name: 'Eagle', virtue: 'Vision', color: '#3B82F6' },
  { id: 5, name: 'Wolf', virtue: 'Loyalty', color: '#6B7280' },
  { id: 6, name: 'Bear', virtue: 'Protection', color: '#92400E' },
  { id: 7, name: 'Lion', virtue: 'Leadership', color: '#EAB308' },
] as const;
'@
        
        $this.WriteFile("src/lib/web3/contracts.ts", $contractConfig)
    }
    
    hidden [void] CreateStateManagement() {
        $storeCode = @'
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

interface BushidoState {
  // Launch state
  isStealthMode: boolean;
  launchTime: Date | null;
  countdownActive: boolean;
  
  // Mint state
  mintedTokens: number[];
  selectedClan: number | null;
  mintQuantity: number;
  
  // Episode & Voting state
  currentEpisode: number;
  votingDeadline: Date | null;
  userVotes: Record<number, number>;
  episodeResults: Record<number, number[]>;
  
  // UI state
  modalOpen: string | null;
  sidebarCollapsed: boolean;
  
  // Actions
  setStealthMode: (mode: boolean) => void;
  setLaunchTime: (time: Date | null) => void;
  setSelectedClan: (clan: number | null) => void;
  setMintQuantity: (quantity: number) => void;
  recordMint: (tokenIds: number[]) => void;
  recordVote: (episode: number, choice: number) => void;
  setModal: (modal: string | null) => void;
  toggleSidebar: () => void;
}

export const useBushidoStore = create<BushidoState>()(
  devtools(
    persist(
      immer((set) => ({
        // Initial state
        isStealthMode: true,
        launchTime: null,
        countdownActive: true,
        mintedTokens: [],
        selectedClan: null,
        mintQuantity: 1,
        currentEpisode: 1,
        votingDeadline: null,
        userVotes: {},
        episodeResults: {},
        modalOpen: null,
        sidebarCollapsed: false,
        
        // Actions
        setStealthMode: (mode) => set((state) => {
          state.isStealthMode = mode;
        }),
        
        setLaunchTime: (time) => set((state) => {
          state.launchTime = time;
          state.countdownActive = time ? new Date() < time : false;
        }),
        
        setSelectedClan: (clan) => set((state) => {
          state.selectedClan = clan;
        }),
        
        setMintQuantity: (quantity) => set((state) => {
          state.mintQuantity = Math.min(Math.max(1, quantity), 3);
        }),
        
        recordMint: (tokenIds) => set((state) => {
          state.mintedTokens.push(...tokenIds);
        }),
        
        recordVote: (episode, choice) => set((state) => {
          state.userVotes[episode] = choice;
        }),
        
        setModal: (modal) => set((state) => {
          state.modalOpen = modal;
        }),
        
        toggleSidebar: () => set((state) => {
          state.sidebarCollapsed = !state.sidebarCollapsed;
        }),
      })),
      {
        name: 'bushido-storage',
        partialize: (state) => ({
          mintedTokens: state.mintedTokens,
          userVotes: state.userVotes,
          sidebarCollapsed: state.sidebarCollapsed,
        }),
      }
    )
  )
);
'@
        
        $this.WriteFile("src/lib/state/store.ts", $storeCode)
    }
    
    hidden [void] CreateUtilities() {
        $utilsCode = @'
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatAddress(address: string): string {
  if (!address) return '';
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

export function formatEther(value: bigint, decimals = 4): string {
  const eth = Number(value) / 1e18;
  return eth.toFixed(decimals);
}

export function getRarityName(rarity: number): string {
  const rarities = ['', 'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'];
  return rarities[rarity] || 'Unknown';
}

export function getRarityColor(rarity: number): string {
  const colors = {
    1: '#6B7280', // Common - Gray
    2: '#10B981', // Uncommon - Green
    3: '#3B82F6', // Rare - Blue
    4: '#8B5CF6', // Epic - Purple
    5: '#F59E0B', // Legendary - Amber
  };
  return colors[rarity as keyof typeof colors] || '#6B7280';
}

export function calculateVotingPower(rarity: number): number {
  return rarity ** 2;
}

export function timeUntil(date: Date): {
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
} {
  const now = new Date();
  const diff = date.getTime() - now.getTime();
  
  if (diff <= 0) {
    return { days: 0, hours: 0, minutes: 0, seconds: 0 };
  }
  
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  const seconds = Math.floor((diff % (1000 * 60)) / 1000);
  
  return { days, hours, minutes, seconds };
}
'@
        
        $this.WriteFile("src/lib/utils/helpers.ts", $utilsCode)
    }
    
    hidden [void] CreateTypes() {
        $typesCode = @'
export interface TokenMetadata {
  tokenId: number;
  clan: number;
  clanName: string;
  rarity: number;
  votingPower: number;
  image: string;
  attributes: TokenAttribute[];
}

export interface TokenAttribute {
  trait_type: string;
  value: string | number;
}

export interface Episode {
  id: number;
  title: string;
  description: string;
  videoUrl: string;
  thumbnailUrl: string;
  releaseDate: Date;
  votingDeadline: Date;
  choices: VoteChoice[];
}

export interface VoteChoice {
  id: number;
  text: string;
  description: string;
  votes: number;
}

export interface VoteResult {
  episodeId: number;
  choice: number;
  votingPower: number;
  timestamp: Date;
}

export interface ClanStats {
  clanId: number;
  totalTokens: number;
  totalVotingPower: number;
  activeVoters: number;
}
'@
        
        $this.WriteFile("src/types/bushido.ts", $typesCode)
    }
    
    hidden [void] SetupBackend() {
        $this.Logger.LogEvent("BackendSetup", @{ Message = "Creating Express backend API" })
        
        $backendPath = "backend"
        
        $this.ExecuteWithCompensation(
            {
                New-Item -ItemType Directory -Path $backendPath -Force | Out-Null
                
                Push-Location $backendPath
                try {
                    # Create package.json
                    $packageJson = @{
                        name = "@bushido/backend"
                        version = "1.0.0"
                        private = $true
                        type = "module"
                        scripts = @{
                            "dev" = "nodemon src/index.ts"
                            "build" = "tsc"
                            "start" = "node dist/index.js"
                            "test" = "jest"
                            "lint" = "eslint src --ext .ts"
                        }
                        dependencies = @{
                            "express" = "^4.18.2"
                            "cors" = "^2.8.5"
                            "helmet" = "^7.1.0"
                            "compression" = "^1.7.4"
                            "ethers" = "^6.10.0"
                            "ioredis" = "^5.3.2"
                            "ipfs-http-client" = "^60.0.1"
                            "dotenv" = "^16.3.1"
                            "zod" = "^3.22.4"
                        }
                        devDependencies = @{
                            "@types/express" = "^4.17.21"
                            "@types/node" = "^20.11.0"
                            "@types/cors" = "^2.8.17"
                            "@types/compression" = "^1.7.5"
                            "typescript" = "^5.3.3"
                            "nodemon" = "^3.0.2"
                            "ts-node" = "^10.9.2"
                            "@typescript-eslint/eslint-plugin" = "^6.19.0"
                            "@typescript-eslint/parser" = "^6.19.0"
                            "jest" = "^29.7.0"
                            "@types/jest" = "^29.5.11"
                            "ts-jest" = "^29.1.1"
                        }
                    }
                    
                    $this.WriteJsonFile("package.json", $packageJson)
                    
                    # Create directory structure
                    @(
                        "src",
                        "src/routes",
                        "src/services",
                        "src/middleware",
                        "src/utils",
                        "src/types"
                    ) | ForEach-Object {
                        New-Item -ItemType Directory -Path $_ -Force | Out-Null
                    }
                    
                    # Create main server file
                    $this.CreateBackendServer()
                    
                    # Create TypeScript config
                    $tsConfig = @{
                        compilerOptions = @{
                            target = "ES2022"
                            module = "NodeNext"
                            moduleResolution = "NodeNext"
                            lib = @("ES2022")
                            outDir = "./dist"
                            rootDir = "./src"
                            strict = $true
                            esModuleInterop = $true
                            skipLibCheck = $true
                            forceConsistentCasingInFileNames = $true
                            resolveJsonModule = $true
                            noImplicitAny = $true
                        }
                        include = @("src/**/*")
                        exclude = @("node_modules", "dist")
                    }
                    
                    $this.WriteJsonFile("tsconfig.json", $tsConfig)
                    
                    $this.Logger.LogEvent("BackendSetupComplete", @{
                        Path = $backendPath
                    }, "Success")
                }
                finally {
                    Pop-Location
                }
            },
            {
                Remove-Item $backendPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        )
    }
    
    hidden [void] CreateBackendServer() {
        $serverCode = @'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import { config } from 'dotenv';
import { createServer } from 'http';

// Load environment variables
config();

const app = express();
const httpServer = createServer(app);

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true,
}));
app.use(compression());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Routes will be added here
// app.use('/api/voting', votingRouter);
// app.use('/api/metadata', metadataRouter);
// app.use('/api/episodes', episodesRouter);

// Error handling
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 4000;

httpServer.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

export default app;
'@
        
        $this.WriteFile("src/index.ts", $serverCode)
    }
    
    hidden [void] SetupScripts() {
        $this.Logger.LogEvent("ScriptsSetup", @{ Message = "Creating deployment and utility scripts" })
        
        $scriptsPath = "scripts"
        
        $this.ExecuteWithCompensation(
            {
                New-Item -ItemType Directory -Path $scriptsPath -Force | Out-Null
                
                Push-Location $scriptsPath
                try {
                    # Create package.json
                    $packageJson = @{
                        name = "@bushido/scripts"
                        version = "1.0.0"
                        private = $true
                        type = "module"
                        scripts = @{
                            "generate-metadata" = "ts-node src/generate-metadata.ts"
                            "upload-ipfs" = "ts-node src/upload-ipfs.ts"
                            "deploy-contracts" = "ts-node src/deploy.ts"
                            "verify-contracts" = "ts-node src/verify.ts"
                        }
                        devDependencies = @{
                            "typescript" = "^5.3.3"
                            "ts-node" = "^10.9.2"
                            "@types/node" = "^20.11.0"
                            "ipfs-http-client" = "^60.0.1"
                            "ethers" = "^6.10.0"
                            "dotenv" = "^16.3.1"
                            "chalk" = "^5.3.0"
                            "ora" = "^8.0.1"
                        }
                    }
                    
                    $this.WriteJsonFile("package.json", $packageJson)
                    
                    # Create directory structure
                    New-Item -ItemType Directory -Path "src" -Force | Out-Null
                    
                    # Create metadata generation script
                    $this.CreateMetadataScript()
                    
                    $this.Logger.LogEvent("ScriptsSetupComplete", @{
                        Path = $scriptsPath
                    }, "Success")
                }
                finally {
                    Pop-Location
                }
            },
            {
                Remove-Item $scriptsPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        )
        
        # Process final configuration
        $this.StateMachine.ProcessEvent([SetupEvent]::DependenciesInstalled)
        $this.CreateFinalConfiguration()
        $this.StateMachine.ProcessEvent([SetupEvent]::ConfigurationComplete)
    }
    
    hidden [void] CreateMetadataScript() {
        $metadataScript = @'
import { create } from 'ipfs-http-client';
import fs from 'fs/promises';
import path from 'path';
import chalk from 'chalk';
import ora from 'ora';

const IPFS_GATEWAY = 'https://ipfs.io/ipfs/';
const TOTAL_SUPPLY = 1600;
const TOKENS_PER_CLAN = 200;

const CLANS = [
  'Dragon', 'Phoenix', 'Tiger', 'Serpent',
  'Eagle', 'Wolf', 'Bear', 'Lion'
];

const RARITIES = ['Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'];

interface Metadata {
  name: string;
  description: string;
  image: string;
  external_url: string;
  attributes: Array<{
    trait_type: string;
    value: string | number;
  }>;
}

async function generateMetadata() {
  const spinner = ora('Generating metadata for 1600 NFTs').start();
  
  try {
    await fs.mkdir('output/metadata', { recursive: true });
    
    for (let tokenId = 1; tokenId <= TOTAL_SUPPLY; tokenId++) {
      const clanIndex = Math.floor((tokenId - 1) / TOKENS_PER_CLAN);
      const clan = CLANS[clanIndex];
      const rarity = getRarity(tokenId);
      const votingPower = calculateVotingPower(rarity);
      
      const metadata: Metadata = {
        name: `Bushido Samurai #${tokenId}`,
        description: `A legendary warrior of the ${clan} Clan, embodying the virtues of Bushido. This warrior possesses ${RARITIES[rarity - 1]} abilities and wields ${votingPower} voting power in shaping the fate of the clans.`,
        image: `${IPFS_GATEWAY}QmYourImageHash/${tokenId}.png`, // Update after uploading images
        external_url: `https://bushido-nft.com/samurai/${tokenId}`,
        attributes: [
          {
            trait_type: 'Clan',
            value: clan,
          },
          {
            trait_type: 'Rarity',
            value: RARITIES[rarity - 1],
          },
          {
            trait_type: 'Voting Power',
            value: votingPower,
          },
          {
            trait_type: 'Generation',
            value: 1,
          },
          {
            trait_type: 'Episode Eligible',
            value: 'Season 1',
          },
        ],
      };
      
      await fs.writeFile(
        path.join('output/metadata', `${tokenId}.json`),
        JSON.stringify(metadata, null, 2)
      );
      
      if (tokenId % 100 === 0) {
        spinner.text = `Generated ${tokenId}/${TOTAL_SUPPLY} metadata files`;
      }
    }
    
    spinner.succeed(chalk.green(`Successfully generated ${TOTAL_SUPPLY} metadata files`));
    
    // Create metadata summary
    await createMetadataSummary();
    
  } catch (error) {
    spinner.fail(chalk.red('Failed to generate metadata'));
    throw error;
  }
}

function getRarity(tokenId: number): number {
  // Deterministic rarity based on token ID
  const hash = simpleHash(tokenId.toString());
  const rand = hash % 10000;
  
  if (rand < 100) return 5;    // Legendary (1%)
  if (rand < 500) return 4;    // Epic (4%)
  if (rand < 1500) return 3;   // Rare (10%)
  if (rand < 3500) return 2;   // Uncommon (20%)
  return 1;                     // Common (65%)
}

function calculateVotingPower(rarity: number): number {
  return rarity ** 2;
}

function simpleHash(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32-bit integer
  }
  return Math.abs(hash);
}

async function createMetadataSummary() {
  const summary = {
    totalSupply: TOTAL_SUPPLY,
    clans: CLANS.map((clan, index) => ({
      name: clan,
      tokenRange: `${index * TOKENS_PER_CLAN + 1}-${(index + 1) * TOKENS_PER_CLAN}`,
    })),
    rarityDistribution: {},
    votingPowerDistribution: {},
  };
  
  // Calculate distributions
  for (let i = 1; i <= TOTAL_SUPPLY; i++) {
    const rarity = getRarity(i);
    const rarityName = RARITIES[rarity - 1];
    summary.rarityDistribution[rarityName] = (summary.rarityDistribution[rarityName] || 0) + 1;
    
    const votingPower = calculateVotingPower(rarity);
    summary.votingPowerDistribution[votingPower] = (summary.votingPowerDistribution[votingPower] || 0) + 1;
  }
  
  await fs.writeFile(
    'output/metadata-summary.json',
    JSON.stringify(summary, null, 2)
  );
  
  console.log(chalk.blue('\nMetadata Summary:'));
  console.log(chalk.gray('Rarity Distribution:'));
  Object.entries(summary.rarityDistribution).forEach(([rarity, count]) => {
    console.log(`  ${rarity}: ${count} (${((count as number / TOTAL_SUPPLY) * 100).toFixed(1)}%)`);
  });
}

// Run the script
generateMetadata().catch(console.error);
'@
        
        $this.WriteFile("src/generate-metadata.ts", $metadataScript)
    }
    
    hidden [void] CreateFinalConfiguration() {
        $this.Logger.LogEvent("FinalConfiguration", @{ Message = "Creating project configuration files" })
        
        # .gitignore
        $gitignore = @"
# Dependencies
node_modules/
.pnpm-store/

# Production builds
build/
dist/
out/
.next/
.turbo/
artifacts/
cache/
typechain-types/

# Environment files
.env
.env*.local

# Logs and debug
logs/
*.log
npm-debug.log*
pnpm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnpm-debug.log*

# Testing
coverage/
.nyc_output/
test-results/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# Temporary files
*.tmp
.cache/
tmp/

# IPFS
output/
"@
        $this.WriteFile(".gitignore", $gitignore)
        
        # .prettierrc
        $prettierrc = @{
            semi = $true
            singleQuote = $true
            trailingComma = "es5"
            printWidth = 100
            tabWidth = 2
            useTabs = $false
            arrowParens = "always"
            endOfLine = "lf"
            plugins = @("prettier-plugin-solidity", "prettier-plugin-tailwindcss")
            overrides = @(
                @{
                    files = "*.sol"
                    options = @{
                        printWidth = 120
                        tabWidth = 4
                        singleQuote = $false
                    }
                }
            )
        }
        
        $this.WriteJsonFile(".prettierrc", $prettierrc)
        
        # .eslintrc.json
        $eslintConfig = @{
            root = $true
            extends = @(
                "eslint:recommended",
                "plugin:@typescript-eslint/recommended",
                "plugin:react/recommended",
                "plugin:react-hooks/recommended",
                "plugin:@next/next/recommended",
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
                "@typescript-eslint/no-unused-vars" = @("warn", @{
                    argsIgnorePattern = "^_"
                    varsIgnorePattern = "^_"
                })
            }
            settings = @{
                react = @{
                    version = "detect"
                }
            }
            env = @{
                browser = $true
                es2021 = $true
                node = $true
            }
        }
        
        $this.WriteJsonFile(".eslintrc.json", $eslintConfig)
        
        # .env.example
        $envExample = @"
# Blockchain Configuration
PRIVATE_KEY=your_private_key_here
ABSTRACT_TESTNET_RPC=https://api.testnet.abs.xyz
ABSTRACT_MAINNET_RPC=https://api.abs.xyz
ABSTRACT_EXPLORER_API_KEY=

# Frontend Configuration
NEXT_PUBLIC_NETWORK=testnet
NEXT_PUBLIC_CONTRACT_ADDRESS=
NEXT_PUBLIC_ALCHEMY_KEY=
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=

# Backend Configuration
PORT=4000
FRONTEND_URL=http://localhost:3000
REDIS_URL=redis://localhost:6379

# IPFS Configuration
PINATA_API_KEY=
PINATA_SECRET_KEY=
IPFS_GATEWAY=https://gateway.pinata.cloud/ipfs/

# Analytics & Monitoring
NEXT_PUBLIC_GA_ID=
SENTRY_DSN=

# External APIs
COINMARKETCAP_API_KEY=
"@
        $this.WriteFile(".env.example", $envExample)
        
        # README.md
        $readme = @"
# 🏯 Bushido NFT - Interactive Anime Storytelling

An innovative NFT project that combines digital collectibles with episodic anime storytelling, where holders shape the narrative through on-chain voting.

## 🌟 Features

- **1,600 Unique Samurai NFTs** across 8 clans
- **Interactive Storytelling** - Vote on episode outcomes
- **Sophisticated Voting System** - Power based on NFT rarity
- **Stealth Launch** on Abstract L2
- **3D Visualizations** with Three.js
- **Real-time Updates** via WebSocket

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- pnpm 8+
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/bushido-nft.git
cd bushido-nft

# Install dependencies
pnpm install

# Copy environment variables
cp .env.example .env
# Edit .env with your configuration

# Start development servers
pnpm dev
```

### Available Scripts

- `pnpm dev` - Start all development servers
- `pnpm build` - Build for production
- `pnpm test` - Run test suites
- `pnpm deploy:testnet` - Deploy to Abstract testnet
- `pnpm deploy:mainnet` - Deploy to Abstract mainnet

## 📁 Project Structure

```
bushido-nft/
├── contracts/          # Smart contracts (Hardhat)
├── frontend/           # Next.js 14 application
├── backend/            # Express API server
├── scripts/            # Deployment and utility scripts
└── docs/              # Documentation
```

## 🔧 Configuration

### Smart Contracts

The main NFT contract includes:
- ERC721 with enumerable extension
- Role-based access control
- Integrated voting mechanics
- Pausable functionality

### Frontend

Built with:
- Next.js 14 (App Router)
- TypeScript
- Tailwind CSS
- Wagmi + RainbowKit
- Three.js for 3D
- Framer Motion

### Backend

Express server featuring:
- RESTful API
- WebSocket support
- Redis caching
- IPFS integration

## 🎨 The Eight Clans

1. **Dragon** - Courage
2. **Phoenix** - Rebirth
3. **Tiger** - Strength
4. **Serpent** - Wisdom
5. **Eagle** - Vision
6. **Wolf** - Loyalty
7. **Bear** - Protection
8. **Lion** - Leadership

## 📺 Episode System

- Weekly episode releases
- 4 choices per episode
- Voting power based on NFT rarity
- Results influence next episode

## 🔐 Security

- Audited smart contracts
- Role-based permissions
- Reentrancy protection
- Comprehensive test coverage

## 📄 License

MIT License - see LICENSE file

## 🤝 Contributing

We welcome contributions! Please see CONTRIBUTING.md for guidelines.

## 📞 Contact

- Website: https://bushido-nft.com
- Twitter: @BushidoNFT
- Discord: discord.gg/bushido
"@
        $this.WriteFile("README.md", $readme)
        
        # .nvmrc for Node version
        $this.WriteFile(".nvmrc", "18.19.0")
    }
    
    # Utility methods
    hidden [void] ExecuteWithCompensation([ScriptBlock]$action, [ScriptBlock]$compensation) {
        try {
            & $action
            $this.CompensationStack.Push($compensation)
        }
        catch {
            $this.ExecuteCompensation()
            throw
        }
    }
    
    hidden [void] ExecuteCompensation() {
        while ($this.CompensationStack.Count -gt 0) {
            $compensation = $this.CompensationStack.Pop()
            try {
                & $compensation
            }
            catch {
                $this.Logger.LogEvent("CompensationFailed", @{
                    Error = $_.Exception.Message
                }, "Warning")
            }
        }
    }
    
    hidden [void] WriteFile([string]$path, [string]$content) {
        $directory = Split-Path -Parent $path
        if ($directory -and -not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        
        # Atomic write
        $tempFile = "$path.tmp"
        Set-Content -Path $tempFile -Value $content -Encoding UTF8 -NoNewline
        Move-Item -Path $tempFile -Destination $path -Force
    }
    
    hidden [void] WriteJsonFile([string]$path, [object]$content) {
        $json = $content | ConvertTo-Json -Depth 10 -Compress:$false
        $this.WriteFile($path, $json)
    }
}

# ═══════════════════════════════════════════════════════════════════
# Main Orchestrator
# ═══════════════════════════════════════════════════════════════════

class BushidoSetupOrchestrator {
    hidden [ServiceContainer]$Container
    hidden [EventSourcedLogger]$Logger
    hidden [SetupStateMachine]$StateMachine
    hidden [BushidoProjectBuilder]$Builder
    hidden [hashtable]$Configuration
    
    BushidoSetupOrchestrator([hashtable]$config = @{}) {
        $this.Configuration = @{
            ProjectPath = Get-Location
            MinimalSetup = $false
            SkipPrerequisites = $false
        }
        
        # Merge provided configuration
        foreach ($key in $config.Keys) {
            $this.Configuration[$key] = $config[$key]
        }
        
        $this.InitializeServices()
    }
    
    hidden [void] InitializeServices() {
        $this.Container = [ServiceContainer]::new()
        
        # Register configuration
        $this.Container.RegisterSingleton("Configuration", $this.Configuration)
        
        # Register logger
        $this.Container.RegisterFactory("Logger", {
            [EventSourcedLogger]::new($this.Configuration.ProjectPath)
        }.GetNewClosure())
        
        # Register state machine
        $this.Container.RegisterFactory("StateMachine", {
            [SetupStateMachine]::new()
        }.GetNewClosure())
        
        # Get instances
        $this.Logger = $this.Container.Resolve("Logger")
        $this.StateMachine = $this.Container.Resolve("StateMachine")
        
        # Register state change callback
        $this.StateMachine.RegisterStateChangeCallback({
            param($previousState, $newState, $event, $context)
            $this.Logger.LogEvent("StateTransition", @{
                PreviousState = $previousState.ToString()
                NewState = $newState.ToString()
                Event = $event.ToString()
                Message = "State machine transitioned"
            })
        }.GetNewClosure())
        
        # Create builder
        $this.Builder = [BushidoProjectBuilder]::new($this.Container)
    }
    
    [void] Execute() {
        try {
            $this.ShowBanner()
            
            $this.Logger.LogEvent("SetupStarted", @{
                Message = "Bushido NFT project setup initiated"
                Configuration = $this.Configuration
            })
            
            # Execute the build process
            $this.Builder.Build()
            
            # Check final state
            $finalState = $this.StateMachine.GetCurrentState()
            
            if ($finalState -eq [SetupState]::Completed) {
                $this.ShowSuccess()
            } else {
                $this.ShowFailure()
            }
            
        } catch {
            $this.Logger.LogEvent("SetupFailed", @{
                Message = $_.Exception.Message
                StackTrace = $_.ScriptStackTrace
            }, "Critical")
            
            $this.ShowFailure()
            throw
        } finally {
            # Show metrics
            $metrics = $this.Logger.GetMetrics()
            $this.Logger.LogEvent("SetupMetrics", @{
                Metrics = $metrics
                Duration = ((Get-Date) - $this.Configuration.StartTime).TotalSeconds
            })
            
            # Cleanup
            $this.Container.Dispose()
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
        
        # Add setup information
        Write-Host "    🎯 Setup Configuration:" -ForegroundColor Yellow
        Write-Host "       Project Path: " -NoNewline -ForegroundColor White
        Write-Host $this.Configuration.ProjectPath -ForegroundColor DarkGray
        Write-Host "       Setup Mode: " -NoNewline -ForegroundColor White
        Write-Host $(if ($this.Configuration.MinimalSetup) { "Minimal" } else { "Full" }) -ForegroundColor DarkGray
        Write-Host ""
    }
    
    hidden [void] ShowSuccess() {
        Write-Host "`n    ✨ " -NoNewline -ForegroundColor Magenta
        Write-Host "PROJECT SETUP COMPLETE!" -ForegroundColor White
        Write-Host "    ═══════════════════════════════════════════════════" -ForegroundColor DarkGreen
        
        Write-Host "`n    🚀 Next Steps:" -ForegroundColor Cyan
        Write-Host "       1. Install dependencies:    " -NoNewline -ForegroundColor White
        Write-Host "pnpm install" -ForegroundColor Yellow
        Write-Host "       2. Configure environment:   " -NoNewline -ForegroundColor White
        Write-Host "cp .env.example .env" -ForegroundColor Yellow
        Write-Host "       3. Start development:       " -NoNewline -ForegroundColor White
        Write-Host "pnpm dev" -ForegroundColor Yellow
        
        Write-Host "`n    📋 Available Commands:" -ForegroundColor Magenta
        Write-Host "       pnpm dev              " -NoNewline -ForegroundColor White
        Write-Host "# Start all services" -ForegroundColor DarkGray
        Write-Host "       pnpm build            " -NoNewline -ForegroundColor White
        Write-Host "# Build for production" -ForegroundColor DarkGray
        Write-Host "       pnpm test             " -NoNewline -ForegroundColor White
        Write-Host "# Run test suites" -ForegroundColor DarkGray
        Write-Host "       pnpm deploy:testnet   " -NoNewline -ForegroundColor White
        Write-Host "# Deploy to testnet" -ForegroundColor DarkGray
        
        Write-Host "`n    📖 Documentation:" -ForegroundColor Blue
        Write-Host "       README.md             " -NoNewline -ForegroundColor White
        Write-Host "# Project overview" -ForegroundColor DarkGray
        Write-Host "       docs/                 " -NoNewline -ForegroundColor White
        Write-Host "# Detailed guides`n" -ForegroundColor DarkGray
    }
    
    hidden [void] ShowFailure() {
        Write-Host "`n    ❌ " -NoNewline -ForegroundColor Red
        Write-Host "Setup encountered errors" -ForegroundColor White
        Write-Host "    ═══════════════════════════════════════════════════" -ForegroundColor DarkRed
        
        Write-Host "`n    📋 Debug Information:" -ForegroundColor Yellow
        Write-Host "       Current State: " -NoNewline -ForegroundColor White
        Write-Host $this.StateMachine.GetCurrentState() -ForegroundColor Red
        Write-Host "       Log Location: " -NoNewline -ForegroundColor White
        Write-Host (Join-Path $this.Configuration.ProjectPath "logs/setup-events.json") -ForegroundColor Gray
        
        Write-Host "`n    💡 Troubleshooting:" -ForegroundColor Cyan
        Write-Host "       - Check prerequisites are installed" -ForegroundColor White
        Write-Host "       - Ensure you have admin privileges" -ForegroundColor White
        Write-Host "       - Review the log file for details`n" -ForegroundColor White
    }
}

# ═══════════════════════════════════════════════════════════════════
# Script Entry Point
# ═══════════════════════════════════════════════════════════════════

# Parse command line arguments
param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = (Get-Location).Path,
    
    [Parameter(Mandatory=$false)]
    [switch]$MinimalSetup,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipPrerequisites,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

if ($Help) {
    Write-Host @"

Bushido NFT Enhanced Setup Script

USAGE:
    .\Bushido-Enhanced-Setup.ps1 [options]

OPTIONS:
    -ProjectPath <path>      Specify project directory (default: current)
    -MinimalSetup           Create minimal structure without full packages
    -SkipPrerequisites      Skip prerequisite checks
    -Help                   Show this help message

EXAMPLES:
    .\Bushido-Enhanced-Setup.ps1
    .\Bushido-Enhanced-Setup.ps1 -ProjectPath C:\Projects\bushido-nft
    .\Bushido-Enhanced-Setup.ps1 -MinimalSetup -SkipPrerequisites

"@
    exit 0
}

# Execute setup
try {
    $config = @{
        ProjectPath = $ProjectPath
        MinimalSetup = $MinimalSetup.IsPresent
        SkipPrerequisites = $SkipPrerequisites.IsPresent
        StartTime = Get-Date
    }
    
    $orchestrator = [BushidoSetupOrchestrator]::new($config)
    $orchestrator.Execute()
    
} catch {
    Write-Host "`n💥 Fatal Error: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    exit 1
}