# setup-prerequisites.ps1
# Bushido NFT Project Prerequisites Installer
# Compatible with PowerShell 7.5.1+

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = "C:\Users\$env:USERNAME\bushido-nft"
)

# Enhanced error handling with custom error messages
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Utility functions for elegant output
function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    $colors = @{
        "Info" = "Cyan"
        "Success" = "Green"
        "Warning" = "Yellow"
        "Error" = "Red"
    }
    Write-Host "[$Type] " -ForegroundColor $colors[$Type] -NoNewline
    Write-Host $Message
}

function Test-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Chocolatey {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Status "Installing Chocolatey package manager..." "Info"
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Status "Chocolatey installed successfully" "Success"
    } else {
        Write-Status "Chocolatey already installed" "Success"
    }
}

function Install-Prerequisites {
    Write-Status "Installing project prerequisites..." "Info"
    
    # Install Node.js LTS if not present
    if (!(Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Status "Installing Node.js LTS..." "Info"
        choco install nodejs-lts -y
        refreshenv
    } else {
        $nodeVersion = node --version
        Write-Status "Node.js $nodeVersion already installed" "Success"
    }
    
    # Install pnpm
    if (!(Get-Command pnpm -ErrorAction SilentlyContinue)) {
        Write-Status "Installing pnpm..." "Info"
        npm install -g pnpm
        Write-Status "pnpm installed successfully" "Success"
    } else {
        $pnpmVersion = pnpm --version
        Write-Status "pnpm $pnpmVersion already installed" "Success"
    }
    
    # Install Git if not present
    if (!(Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Status "Installing Git..." "Info"
        choco install git -y
        refreshenv
    } else {
        Write-Status "Git already installed" "Success"
    }
    
    # Install additional tools
    Write-Status "Installing additional development tools..." "Info"
    npm install -g typescript ts-node nodemon
}

# Main execution
try {
    Write-Host "`n🔥 Bushido NFT Prerequisites Setup 🔥`n" -ForegroundColor Red
    
    if (!(Test-AdminPrivileges)) {
        Write-Status "This script requires administrator privileges. Restarting as admin..." "Warning"
        Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
    
    Install-Chocolatey
    refreshenv
    Install-Prerequisites
    
    Write-Host "`n✅ All prerequisites installed successfully!`n" -ForegroundColor Green
    Write-Host "You can now proceed with the project setup.`n" -ForegroundColor Cyan
    
} catch {
    Write-Status "An error occurred: $_" "Error"
    exit 1
}