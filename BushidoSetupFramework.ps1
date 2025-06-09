# BushidoSetupFramework.psm1
# A sophisticated, production-grade setup framework for Bushido NFT
# Designed for PowerShell 7.5.1+ with enterprise-level patterns

using namespace System.Management.Automation
using namespace System.Collections.Generic
using namespace System.IO

# Advanced configuration management
class BushidoConfiguration {
    [string]$ProjectRoot
    [hashtable]$Dependencies
    [hashtable]$EnvironmentVariables
    [version]$MinimumNodeVersion
    [version]$MinimumPnpmVersion
    [bool]$UseYarn
    [string]$PackageManager
    
    BushidoConfiguration() {
        $this.ProjectRoot = Join-Path $env:USERPROFILE "bushido-nft"
        $this.MinimumNodeVersion = [version]"18.0.0"
        $this.MinimumPnpmVersion = [version]"8.0.0"
        $this.PackageManager = "pnpm"
        $this.Dependencies = @{
            "Node.js" = @{
                Command = "node"
                ChocoPackage = "nodejs-lts"
                VersionCommand = "node --version"
                VersionRegex = "v(\d+\.\d+\.\d+)"
                MinVersion = $this.MinimumNodeVersion
            }
            "pnpm" = @{
                Command = "pnpm"
                NpmPackage = "pnpm"
                VersionCommand = "pnpm --version"
                VersionRegex = "(\d+\.\d+\.\d+)"
                MinVersion = $this.MinimumPnpmVersion
            }
            "Git" = @{
                Command = "git"
                ChocoPackage = "git"
                VersionCommand = "git --version"
                VersionRegex = "git version (\d+\.\d+\.\d+)"
                Optional = $false
            }
        }
    }
}

# Sophisticated logging system with multiple output targets
class BushidoLogger {
    [string]$LogPath
    [System.Collections.ArrayList]$LogBuffer
    hidden [hashtable]$ColorScheme
    hidden [int]$IndentLevel = 0
    
    BushidoLogger([string]$projectRoot) {
        $this.LogPath = Join-Path $projectRoot "setup.log"
        $this.LogBuffer = [System.Collections.ArrayList]::new()
        $this.ColorScheme = @{
            "Info"     = @{ Foreground = "Cyan"; Symbol = "ℹ" }
            "Success"  = @{ Foreground = "Green"; Symbol = "✓" }
            "Warning"  = @{ Foreground = "Yellow"; Symbol = "⚠" }
            "Error"    = @{ Foreground = "Red"; Symbol = "✗" }
            "Debug"    = @{ Foreground = "DarkGray"; Symbol = "🔍" }
            "Special"  = @{ Foreground = "Magenta"; Symbol = "✨" }
            "Progress" = @{ Foreground = "Blue"; Symbol = "▶" }
        }
        $this.InitializeLogFile()
    }
    
    hidden [void] InitializeLogFile() {
        $logDir = Split-Path $this.LogPath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        $header = @"
════════════════════════════════════════════════════════════════════
Bushido NFT Setup Log - $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
PowerShell Version: $($PSVersionTable.PSVersion)
Operating System: $([System.Environment]::OSVersion.VersionString)
════════════════════════════════════════════════════════════════════
"@
        Set-Content -Path $this.LogPath -Value $header -Encoding UTF8
    }
    
    [void] Log([string]$message, [string]$level = "Info") {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $indent = "  " * $this.IndentLevel
        
        # Console output with sophisticated formatting
        $color = $this.ColorScheme[$level]
        $symbol = $color.Symbol
        
        Write-Host "$indent[$timestamp] " -ForegroundColor DarkGray -NoNewline
        Write-Host "$symbol " -ForegroundColor $color.Foreground -NoNewline
        Write-Host $message
        
        # File logging
        $logEntry = "$timestamp [$level] $indent$message"
        Add-Content -Path $this.LogPath -Value $logEntry -Encoding UTF8
        
        # Buffer for potential error reporting
        $null = $this.LogBuffer.Add(@{
            Timestamp = $timestamp
            Level = $level
            Message = $message
            Indent = $this.IndentLevel
        })
    }
    
    [void] StartSection([string]$sectionName) {
        $this.Log($sectionName, "Special")
        $this.IndentLevel++
    }
    
    [void] EndSection() {
        if ($this.IndentLevel -gt 0) {
            $this.IndentLevel--
        }
    }
    
    [void] LogException([System.Management.Automation.ErrorRecord]$errorRecord) {
        $this.Log("Exception: $($errorRecord.Exception.Message)", "Error")
        $this.IndentLevel++
        $this.Log("Type: $($errorRecord.Exception.GetType().FullName)", "Debug")
        $this.Log("Script: $($errorRecord.InvocationInfo.ScriptName)", "Debug")
        $this.Log("Line: $($errorRecord.InvocationInfo.ScriptLineNumber)", "Debug")
        $this.IndentLevel--
    }
}

# Advanced environment management for PowerShell
class EnvironmentManager {
    hidden [BushidoLogger]$Logger
    hidden [hashtable]$OriginalEnv
    
    EnvironmentManager([BushidoLogger]$logger) {
        $this.Logger = $logger
        $this.OriginalEnv = @{}
        $this.CaptureCurrentEnvironment()
    }
    
    hidden [void] CaptureCurrentEnvironment() {
        $env:Path -split [System.IO.Path]::PathSeparator | ForEach-Object {
            $this.OriginalEnv[$_] = $true
        }
    }
    
    [void] RefreshEnvironment() {
        $this.Logger.Log("Refreshing PowerShell environment variables...", "Info")
        
        # Update PATH from system
        $machineEnvPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
        $userEnvPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
        
        if ($machineEnvPath -and $userEnvPath) {
            $env:Path = "$machineEnvPath;$userEnvPath"
        }
        
        # Refresh Chocolatey environment if available
        $chocoPath = Join-Path $env:ProgramData "chocolatey\helpers\chocolateyProfile.psm1"
        if (Test-Path $chocoPath) {
            Import-Module $chocoPath -Force
            Update-SessionEnvironment
            $this.Logger.Log("Chocolatey environment refreshed", "Success")
        }
        
        # Detect new paths
        $currentPaths = $env:Path -split [System.IO.Path]::PathSeparator
        $newPaths = $currentPaths | Where-Object { -not $this.OriginalEnv.ContainsKey($_) }
        
        if ($newPaths) {
            $this.Logger.Log("New paths detected:", "Info")
            $newPaths | ForEach-Object { $this.Logger.Log("  $_", "Debug") }
        }
    }
    
    [bool] TestCommand([string]$command) {
        $result = Get-Command $command -ErrorAction SilentlyContinue
        return $null -ne $result
    }
    
    [version] GetCommandVersion([string]$command, [string]$versionArg, [string]$regex) {
        try {
            $output = & $command $versionArg 2>&1
            if ($output -match $regex) {
                return [version]$matches[1]
            }
        }
        catch {
            $this.Logger.Log("Failed to get version for $command", "Debug")
        }
        return [version]"0.0.0"
    }
}

# Sophisticated dependency installer with retry logic and validation
class DependencyInstaller {
    hidden [BushidoLogger]$Logger
    hidden [EnvironmentManager]$EnvManager
    hidden [BushidoConfiguration]$Config
    hidden [int]$MaxRetries = 3
    hidden [int]$RetryDelaySeconds = 5
    
    DependencyInstaller([BushidoLogger]$logger, [EnvironmentManager]$envManager, [BushidoConfiguration]$config) {
        $this.Logger = $logger
        $this.EnvManager = $envManager
        $this.Config = $config
    }
    
    [bool] InstallChocolatey() {
        if ($this.EnvManager.TestCommand("choco")) {
            $this.Logger.Log("Chocolatey is already installed", "Success")
            return $true
        }
        
        $this.Logger.StartSection("Installing Chocolatey")
        
        try {
            # Set required security protocols
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            
            # Download and execute Chocolatey install script
            $installScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
            
            # Create a temporary script file to avoid execution policy issues
            $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
            Set-Content -Path $tempScript -Value $installScript -Encoding UTF8
            
            # Execute with bypass
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tempScript
            
            # Cleanup
            Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
            
            # Refresh environment
            $this.EnvManager.RefreshEnvironment()
            
            # Verify installation
            if ($this.EnvManager.TestCommand("choco")) {
                $this.Logger.Log("Chocolatey installed successfully", "Success")
                $this.Logger.EndSection()
                return $true
            }
            else {
                throw "Chocolatey installation completed but command not found"
            }
        }
        catch {
            $this.Logger.LogException($_)
            $this.Logger.EndSection()
            return $false
        }
    }
    
    [bool] InstallDependency([string]$name, [hashtable]$config) {
        $this.Logger.StartSection("Installing $name")
        
        # Check if already installed and meets version requirements
        if ($this.EnvManager.TestCommand($config.Command)) {
            if ($config.ContainsKey("MinVersion")) {
                $currentVersion = $this.EnvManager.GetCommandVersion(
                    $config.Command,
                    $config.VersionCommand.Split(' ')[1],
                    $config.VersionRegex
                )
                
                if ($currentVersion -ge $config.MinVersion) {
                    $this.Logger.Log("$name $currentVersion already installed (minimum: $($config.MinVersion))", "Success")
                    $this.Logger.EndSection()
                    return $true
                }
                else {
                    $this.Logger.Log("$name $currentVersion is below minimum required version $($config.MinVersion)", "Warning")
                }
            }
            else {
                $this.Logger.Log("$name is already installed", "Success")
                $this.Logger.EndSection()
                return $true
            }
        }
        
        # Install with retry logic
        $retryCount = 0
        while ($retryCount -lt $this.MaxRetries) {
            try {
                if ($config.ContainsKey("ChocoPackage")) {
                    $this.Logger.Log("Installing via Chocolatey: $($config.ChocoPackage)", "Info")
                    $result = choco install $config.ChocoPackage -y --no-progress 2>&1
                    
                    if ($LASTEXITCODE -eq 0) {
                        $this.EnvManager.RefreshEnvironment()
                        
                        if ($this.EnvManager.TestCommand($config.Command)) {
                            $this.Logger.Log("$name installed successfully", "Success")
                            $this.Logger.EndSection()
                            return $true
                        }
                    }
                    else {
                        throw "Chocolatey install failed with exit code: $LASTEXITCODE"
                    }
                }
                elseif ($config.ContainsKey("NpmPackage")) {
                    $this.Logger.Log("Installing via npm: $($config.NpmPackage)", "Info")
                    npm install -g $config.NpmPackage
                    
                    if ($LASTEXITCODE -eq 0) {
                        $this.EnvManager.RefreshEnvironment()
                        
                        if ($this.EnvManager.TestCommand($config.Command)) {
                            $this.Logger.Log("$name installed successfully", "Success")
                            $this.Logger.EndSection()
                            return $true
                        }
                    }
                    else {
                        throw "npm install failed with exit code: $LASTEXITCODE"
                    }
                }
            }
            catch {
                $retryCount++
                $this.Logger.Log("Installation attempt $retryCount failed: $_", "Warning")
                
                if ($retryCount -lt $this.MaxRetries) {
                    $this.Logger.Log("Retrying in $($this.RetryDelaySeconds) seconds...", "Info")
                    Start-Sleep -Seconds $this.RetryDelaySeconds
                }
            }
        }
        
        $this.Logger.Log("Failed to install $name after $($this.MaxRetries) attempts", "Error")
        $this.Logger.EndSection()
        return $false
    }
    
    [bool] InstallAllDependencies() {
        $this.Logger.StartSection("Installing all dependencies")
        
        # First ensure Chocolatey is installed
        if (-not $this.InstallChocolatey()) {
            $this.Logger.Log("Failed to install Chocolatey - cannot proceed", "Error")
            $this.Logger.EndSection()
            return $false
        }
        
        # Install each dependency
        $success = $true
        foreach ($dep in $this.Config.Dependencies.GetEnumerator()) {
            if (-not $dep.Value.Optional -or $dep.Value.Optional -eq $false) {
                if (-not $this.InstallDependency($dep.Key, $dep.Value)) {
                    $success = $false
                    if (-not $dep.Value.Optional) {
                        $this.Logger.Log("Failed to install required dependency: $($dep.Key)", "Error")
                        break
                    }
                }
            }
        }
        
        # Install additional global npm packages
        if ($success -and $this.EnvManager.TestCommand("npm")) {
            $this.Logger.StartSection("Installing global npm packages")
            $globalPackages = @("typescript", "ts-node", "nodemon", "prettier", "eslint")
            
            foreach ($package in $globalPackages) {
                try {
                    $this.Logger.Log("Installing $package globally", "Info")
                    npm install -g $package --silent
                    $this.Logger.Log("$package installed", "Success")
                }
                catch {
                    $this.Logger.Log("Failed to install $package: $_", "Warning")
                }
            }
            $this.Logger.EndSection()
        }
        
        $this.Logger.EndSection()
        return $success
    }
}

# Main setup orchestrator
class BushidoSetupOrchestrator {
    hidden [BushidoConfiguration]$Config
    hidden [BushidoLogger]$Logger
    hidden [EnvironmentManager]$EnvManager
    hidden [DependencyInstaller]$Installer
    
    BushidoSetupOrchestrator() {
        $this.Config = [BushidoConfiguration]::new()
        $this.Logger = [BushidoLogger]::new($this.Config.ProjectRoot)
        $this.EnvManager = [EnvironmentManager]::new($this.Logger)
        $this.Installer = [DependencyInstaller]::new($this.Logger, $this.EnvManager, $this.Config)
    }
    
    [bool] ValidateAdminPrivileges() {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    
    [void] Run() {
        try {
            $this.ShowBanner()
            
            # Validate admin privileges
            if (-not $this.ValidateAdminPrivileges()) {
                $this.Logger.Log("Administrator privileges required. Attempting to restart with elevation...", "Warning")
                $this.RestartAsAdmin()
                return
            }
            
            # Install dependencies
            if ($this.Installer.InstallAllDependencies()) {
                $this.ShowSuccess()
            }
            else {
                $this.ShowFailure()
            }
        }
        catch {
            $this.Logger.LogException($_)
            $this.ShowFailure()
        }
    }
    
    hidden [void] RestartAsAdmin() {
        $arguments = @(
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", "`"$PSCommandPath`""
        )
        
        if ($PSBoundParameters.Count -gt 0) {
            $PSBoundParameters.GetEnumerator() | ForEach-Object {
                $arguments += "-$($_.Key)", $_.Value
            }
        }
        
        Start-Process PowerShell -Verb RunAs -ArgumentList $arguments
        exit
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
                                                            
            N F T   S E T U P   F R A M E W O R K
"@ -ForegroundColor Red
        
        Write-Host "`n    PowerShell $($PSVersionTable.PSVersion) | Windows Terminal Ready" -ForegroundColor DarkGray
        Write-Host "    ═══════════════════════════════════════════════════" -ForegroundColor DarkRed
        Write-Host ""
    }
    
    hidden [void] ShowSuccess() {
        Write-Host "`n    ═══════════════════════════════════════════════════" -ForegroundColor DarkGreen
        Write-Host "    ✅ " -NoNewline -ForegroundColor Green
        Write-Host "All prerequisites installed successfully!" -ForegroundColor White
        Write-Host "    ═══════════════════════════════════════════════════" -ForegroundColor DarkGreen
        Write-Host "`n    Next: Run " -NoNewline -ForegroundColor Cyan
        Write-Host ".\setup-bushido-project.ps1" -ForegroundColor Yellow
        Write-Host "    to create your Bushido NFT project`n" -ForegroundColor Cyan
    }
    
    hidden [void] ShowFailure() {
        Write-Host "`n    ═══════════════════════════════════════════════════" -ForegroundColor DarkRed
        Write-Host "    ❌ " -NoNewline -ForegroundColor Red
        Write-Host "Setup encountered errors" -ForegroundColor White
        Write-Host "    ═══════════════════════════════════════════════════" -ForegroundColor DarkRed
        Write-Host "`n    Check the log file for details:" -ForegroundColor Yellow
        Write-Host "    $($this.Logger.LogPath)`n" -ForegroundColor Gray
    }
}

# Export module members
Export-ModuleMember -Class @(
    'BushidoConfiguration',
    'BushidoLogger',
    'EnvironmentManager', 
    'DependencyInstaller',
    'BushidoSetupOrchestrator'
)

# Execute if running as script
if ($MyInvocation.InvocationName -ne '.') {
    $orchestrator = [BushidoSetupOrchestrator]::new()
    $orchestrator.Run()
}