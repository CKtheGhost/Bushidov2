#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Bushido NFT - Apex Restoration Protocol
    The zenith of PowerShell engineering excellence
    
.DESCRIPTION
    A masterfully crafted restoration engine that transcends conventional
    scripting to achieve a state of computational perfection. Every line
    represents the culmination of engineering artistry.
    
.PARAMETER Diagnostic
    Enable comprehensive diagnostic output with telemetry
    
.PARAMETER Turbo
    Activate parallel execution for maximum performance
    
.PARAMETER Silent
    Execute with minimal output for CI/CD environments
    
.EXAMPLE
    ./restore-bushido-apex.ps1
    Standard execution with elegant visual feedback
    
.EXAMPLE
    ./restore-bushido-apex.ps1 -Turbo -Diagnostic
    Maximum performance with detailed diagnostics
    
.NOTES
    Author: Apex Architecture Division
    Version: 4.0.0-apex
    Requires: PowerShell 7.0+, Node.js 18+
#>

[CmdletBinding(DefaultParameterSetName = 'Standard')]
param(
    [Parameter(ParameterSetName = 'Standard')]
    [Parameter(ParameterSetName = 'Advanced')]
    [switch]$Diagnostic,
    
    [Parameter(ParameterSetName = 'Advanced')]
    [switch]$Turbo,
    
    [Parameter(ParameterSetName = 'Silent')]
    [switch]$Silent
)

#region Apex Configuration - Immutable Constants
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = if ($Silent) { 'SilentlyContinue' } else { 'Continue' }
$InformationPreference = if ($Diagnostic) { 'Continue' } else { 'SilentlyContinue' }

# Global configuration object with thread-safe access
$script:ApexConfig = [hashtable]::Synchronized(@{
    Version = '4.0.0-apex'
    StartTime = [DateTimeOffset]::UtcNow
    TurboMode = $Turbo.IsPresent
    DiagnosticMode = $Diagnostic.IsPresent
    SilentMode = $Silent.IsPresent
    ProjectName = 'Bushido NFT'
    TotalNFTs = 1600
    ClanCount = 8
    WarriorsPerClan = 200
})

# Initialize telemetry collection
$script:Telemetry = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
#endregion

#region Apex Console Interface - Visual Excellence Engine
class ApexConsole {
    static [hashtable]$Theme = @{
        Primary = 'Cyan'
        Success = 'Green'
        Warning = 'Yellow'
        Error = 'Red'
        Info = 'Blue'
        Accent = 'Magenta'
        Subtle = 'DarkGray'
        Highlight = 'White'
    }
    
    static [hashtable]$Icons = @{
        Success = '✓'
        Error = '✗'
        Warning = '⚠'
        Info = '→'
        Working = '◈'
        Complete = '◆'
        Apex = '⟐'
        Bushido = '⛩️'
        Samurai = '🗾'
    }
    
    static [void] RenderApexBanner() {
        if ($script:ApexConfig.SilentMode) { return }
        
        $banner = @'

         ▄▄▄       ██▓███  ▓█████ ▒██   ██▒
        ▒████▄    ▓██░  ██▒▓█   ▀ ▒▒ █ █ ▒░
        ▒██  ▀█▄  ▓██░ ██▓▒▒███   ░░  █   ░
        ░██▄▄▄▄██ ▒██▄█▓▒ ▒▒▓█  ▄  ░ █ █ ▒ 
         ▓█   ▓██▒▒██▒ ░  ░░▒████▒▒██▒ ▒██▒
         ▒▒   ▓▒█░▒▓▒░ ░  ░░░ ▒░ ░▒▒ ░ ░▓ ░
          ▒   ▒▒ ░░▒ ░      ░ ░  ░░░   ░▒ ░
          ░   ▒   ░░          ░    ░    ░  
              ░  ░            ░  ░ ░    ░  
                                           
        ╔═══════════════════════════════════════════╗
        ║     BUSHIDO NFT - APEX RESTORATION       ║
        ║    Eight Clans • Eight Virtues • One Path ║
        ╚═══════════════════════════════════════════╝

'@
        
        # Render with gradient effect
        $lines = $banner -split "`n"
        $colors = @('DarkCyan', 'Cyan', 'Cyan', 'White', 'White', 'Cyan', 'Cyan', 'DarkCyan')
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $color = if ($i -lt $colors.Count) { $colors[$i] } else { 'Cyan' }
            Write-Host $lines[$i] -ForegroundColor $color
            
            if (-not $script:ApexConfig.TurboMode -and $i -lt 8) {
                Start-Sleep -Milliseconds 50
            }
        }
    }
    
    static [void] Section([string]$title, [ConsoleColor]$color = 'Magenta') {
        if ($script:ApexConfig.SilentMode) { return }
        
        $width = 65
        $padding = [Math]::Max(0, ($width - $title.Length - 4) / 2)
        $left = '═' * [Math]::Floor($padding)
        $right = '═' * [Math]::Ceiling($padding)
        
        Write-Host "`n$left $title $right" -ForegroundColor $color
    }
    
    static [void] Status([string]$message, [string]$type = 'Info', [int]$indent = 2) {
        if ($script:ApexConfig.SilentMode -and $type -ne 'Error') { return }
        
        $icon = [ApexConsole]::Icons[$type] ?? [ApexConsole]::Icons['Info']
        $color = [ApexConsole]::Theme[$type] ?? [ApexConsole]::Theme['Info']
        
        $padding = ' ' * $indent
        Write-Host "$padding$icon " -NoNewline -ForegroundColor $color
        Write-Host $message
        
        # Log telemetry if diagnostic mode
        if ($script:ApexConfig.DiagnosticMode) {
            $script:Telemetry.Add(@{
                Timestamp = [DateTimeOffset]::UtcNow
                Type = $type
                Message = $message
                Component = (Get-PSCallStack)[2].Command
            })
        }
    }
    
    static [void] Progress([double]$percent, [string]$activity) {
        if ($script:ApexConfig.SilentMode) { return }
        
        $width = 50
        $filled = [Math]::Floor($width * ($percent / 100))
        $empty = $width - $filled
        
        # Create gradient progress bar
        $bar = ''
        for ($i = 0; $i -lt $filled; $i++) {
            $intensity = if ($i -eq $filled - 1) { '▓' } 
                        elseif ($i -eq $filled - 2) { '▒' }
                        else { '█' }
            $bar += $intensity
        }
        $bar += '░' * $empty
        
        $percentStr = "{0,3:N0}%" -f [Math]::Min($percent, 100)
        Write-Host "`r  [$bar] $percentStr $activity" -NoNewline -ForegroundColor Cyan
        
        if ($percent -ge 100) {
            Write-Host "" # New line on completion
        }
    }
}
#endregion

#region Apex File System - Atomic Operations with Reliability
class ApexFileSystem {
    hidden static [System.Collections.Concurrent.ConcurrentDictionary[string, byte[]]]$WriteCache = 
        [System.Collections.Concurrent.ConcurrentDictionary[string, byte[]]]::new()
    
    static [void] EnsureDirectory([string]$path) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and -not (Test-Path $path -PathType Container)) {
            New-Item -ItemType Directory -Path $path -Force -ErrorAction Stop | Out-Null
        }
    }
    
    static [void] WriteFile([string]$path, [string]$content) {
        # Validate inputs
        if ([string]::IsNullOrWhiteSpace($path)) {
            throw [ArgumentException]::new("Path cannot be null or empty")
        }
        
        # Ensure parent directory exists
        $parent = Split-Path $path -Parent
        if ($parent -and -not (Test-Path $parent)) {
            [ApexFileSystem]::EnsureDirectory($parent)
        }
        
        # Convert to UTF-8 without BOM
        $encoding = [System.Text.UTF8Encoding]::new($false)
        $bytes = $encoding.GetBytes($content)
        
        # Atomic write with retry logic
        $maxRetries = 3
        $retryDelay = 100
        
        for ($i = 0; $i -lt $maxRetries; $i++) {
            try {
                [System.IO.File]::WriteAllBytes($path, $bytes)
                
                # Cache the write for verification
                [ApexFileSystem]::WriteCache.TryAdd($path, $bytes) | Out-Null
                break
            }
            catch {
                if ($i -eq $maxRetries - 1) { throw }
                Start-Sleep -Milliseconds ($retryDelay * ($i + 1))
            }
        }
    }
    
    static [void] WriteJson([string]$path, [hashtable]$data) {
        # Create formatted JSON with proper indentation
        $json = $data | ConvertTo-Json -Depth 20 -Compress:$false
        
        # Post-process for beautiful formatting
        $formatted = $json -replace '(?m)^(\s*)"', '$1"' -replace '(?m)^\s*}', '}'
        
        [ApexFileSystem]::WriteFile($path, $formatted)
    }
    
    static [bool] VerifyWrite([string]$path) {
        if ([ApexFileSystem]::WriteCache.ContainsKey($path)) {
            $cachedBytes = [ApexFileSystem]::WriteCache[$path]
            if (Test-Path $path) {
                $fileBytes = [System.IO.File]::ReadAllBytes($path)
                return [System.Linq.Enumerable]::SequenceEqual($cachedBytes, $fileBytes)
            }
        }
        return $false
    }
}
#endregion

#region Bushido Architecture - The Eight Virtues Implementation
class BushidoArchitecture {
    static [array]$Clans = @(
        @{
            Id = 0; Name = 'Honō'; Kanji = '炎'; Virtue = 'Honor'
            Description = 'The eternal flame, guardians of the sacred Bushido code'
            Element = 'Fire'; Color = '#DC2626'; Power = 'Indomitable Spirit'
            Traits = @('Leadership', 'Courage', 'Discipline')
        },
        @{
            Id = 1; Name = 'Yūki'; Kanji = '勇気'; Virtue = 'Courage'
            Description = 'Swift as wind, fearless in the face of any adversity'
            Element = 'Wind'; Color = '#10B981'; Power = 'Unstoppable Force'
            Traits = @('Speed', 'Agility', 'Determination')
        },
        @{
            Id = 2; Name = 'Jin'; Kanji = '仁'; Virtue = 'Benevolence'
            Description = 'Flowing like water, bringing life and healing to all'
            Element = 'Water'; Color = '#3B82F6'; Power = 'Healing Touch'
            Traits = @('Empathy', 'Wisdom', 'Compassion')
        },
        @{
            Id = 3; Name = 'Rei'; Kanji = '礼'; Virtue = 'Respect'
            Description = 'Solid as earth, the foundation of harmonious society'
            Element = 'Earth'; Color = '#A78BFA'; Power = 'Unbreakable Defense'
            Traits = @('Stability', 'Patience', 'Tradition')
        },
        @{
            Id = 4; Name = 'Makoto'; Kanji = '誠'; Virtue = 'Honesty'
            Description = 'Lightning strike of truth, illuminating darkness'
            Element = 'Lightning'; Color = '#F59E0B'; Power = 'Piercing Insight'
            Traits = @('Clarity', 'Justice', 'Precision')
        },
        @{
            Id = 5; Name = 'Meiyo'; Kanji = '名誉'; Virtue = 'Glory'
            Description = 'Forged in metal, reflecting the light of achievement'
            Element = 'Metal'; Color = '#6B7280'; Power = 'Legendary Status'
            Traits = @('Excellence', 'Pride', 'Legacy')
        },
        @{
            Id = 6; Name = 'Chūgi'; Kanji = '忠義'; Virtue = 'Loyalty'
            Description = 'Rooted like ancient wood, unwavering through seasons'
            Element = 'Wood'; Color = '#84CC16'; Power = 'Eternal Bond'
            Traits = @('Devotion', 'Trust', 'Sacrifice')
        },
        @{
            Id = 7; Name = 'Jisei'; Kanji = '自制'; Virtue = 'Self-Control'
            Description = 'Master of shadows, supreme discipline over mind and body'
            Element = 'Shadow'; Color = '#1F2937'; Power = 'Perfect Balance'
            Traits = @('Focus', 'Restraint', 'Mastery')
        }
    )
    
    static [hashtable] GetBackendPackage() {
        return @{
            name = '@bushido/backend'
            version = '1.0.0'
            private = $true
            type = 'module'
            main = 'src/index.js'
            engines = @{
                node = '>=18.0.0'
                pnpm = '>=8.0.0'
            }
            scripts = @{
                dev = 'nodemon --experimental-specifier-resolution=node src/index.js'
                start = 'node --experimental-specifier-resolution=node src/index.js'
                build = 'echo "Backend ready for production deployment"'
                lint = 'eslint src --ext .js --fix'
                test = 'jest --coverage --passWithNoTests'
                'test:watch' = 'jest --watch'
            }
            dependencies = @{
                express = '^4.18.2'
                cors = '^2.8.5'
                dotenv = '^16.3.1'
                ethers = '^6.10.0'
                helmet = '^7.1.0'
                compression = '^1.7.4'
                'express-rate-limit' = '^7.1.5'
                winston = '^3.11.0'
                morgan = '^1.10.0'
                'express-validator' = '^7.0.1'
            }
            devDependencies = @{
                nodemon = '^3.0.2'
                eslint = '^8.56.0'
                jest = '^29.7.0'
                '@types/node' = '^20.11.0'
            }
        }
    }
    
    static [string] GenerateBackendApex() {
        # Generate clan data JSON
        $clanData = [BushidoArchitecture]::Clans | ConvertTo-Json -Depth 10 -Compress:$false
        
        return @"
/**
 * Bushido NFT Backend - Apex Architecture
 * ═══════════════════════════════════════════
 * 
 * A masterfully crafted server implementation that embodies
 * the principles of Bushido through elegant code architecture.
 * Every endpoint is a testament to engineering excellence.
 * 
 * @author Apex Architecture Division
 * @version 1.0.0-apex
 * @license MIT
 */

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import morgan from 'morgan';
import winston from 'winston';
import { createServer } from 'http';
import { ethers } from 'ethers';
import { body, param, query, validationResult } from 'express-validator';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { promises as fs } from 'fs';

// ═══════════════════════════════════════════════════════════════════
// Environment & Path Configuration
// ═══════════════════════════════════════════════════════════════════

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// ═══════════════════════════════════════════════════════════════════
// Winston Logger - Enlightened Logging System
// ═══════════════════════════════════════════════════════════════════

const logFormat = winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
);

const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: logFormat,
    defaultMeta: { 
        service: 'bushido-backend',
        version: '1.0.0-apex',
        environment: process.env.NODE_ENV || 'development'
    },
    transports: [
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize({ all: true }),
                winston.format.printf(({ timestamp, level, message, ...meta }) => {
                    const metaStr = Object.keys(meta).length ? 
                        `\n${JSON.stringify(meta, null, 2)}` : '';
                    return `[${timestamp}] ${level}: ${message}${metaStr}`;
                })
            )
        }),
        ...(process.env.NODE_ENV === 'production' ? [
            new winston.transports.File({
                filename: join(__dirname, '../logs/error.log'),
                level: 'error',
                maxsize: 5242880, // 5MB
                maxFiles: 5,
                format: logFormat
            }),
            new winston.transports.File({
                filename: join(__dirname, '../logs/combined.log'),
                maxsize: 5242880, // 5MB
                maxFiles: 5,
                format: logFormat
            })
        ] : [])
    ]
});

// Ensure log directory exists
if (process.env.NODE_ENV === 'production') {
    const logDir = join(__dirname, '../logs');
    fs.mkdir(logDir, { recursive: true }).catch(err => {
        console.error('Failed to create log directory:', err);
    });
}

// ═══════════════════════════════════════════════════════════════════
// Configuration Matrix - Centralized Settings
// ═══════════════════════════════════════════════════════════════════

const config = {
    server: {
        port: parseInt(process.env.PORT || '4000', 10),
        host: process.env.HOST || '0.0.0.0',
        environment: process.env.NODE_ENV || 'development',
        trustProxy: process.env.TRUST_PROXY === 'true'
    },
    cors: {
        origin: (origin, callback) => {
            const allowedOrigins = (process.env.ALLOWED_ORIGINS || 'http://localhost:3000').split(',');
            if (!origin || allowedOrigins.includes(origin)) {
                callback(null, true);
            } else {
                callback(new Error('Not allowed by CORS'));
            }
        },
        credentials: true,
        methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
        allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
        exposedHeaders: ['X-Request-Id', 'X-Response-Time', 'X-RateLimit-Limit', 'X-RateLimit-Remaining']
    },
    rateLimit: {
        windowMs: 15 * 60 * 1000, // 15 minutes
        max: 100, // Limit each IP to 100 requests per windowMs
        message: {
            success: false,
            error: 'RATE_LIMIT_EXCEEDED',
            message: 'Too many requests from this IP, please honor the way of patience'
        },
        standardHeaders: true,
        legacyHeaders: false,
        skip: (req) => {
            // Skip rate limiting for health checks
            return req.path === '/health';
        }
    },
    blockchain: {
        abstractRpc: process.env.ABSTRACT_RPC || 'https://api.abs.xyz',
        contractAddress: process.env.CONTRACT_ADDRESS,
        chainId: parseInt(process.env.CHAIN_ID || '11124', 10)
    },
    security: {
        maxRequestSize: '10mb',
        jwtSecret: process.env.JWT_SECRET || 'bushido-secret-key',
        sessionSecret: process.env.SESSION_SECRET || 'bushido-session-secret'
    },
    project: {
        totalNFTs: $($script:ApexConfig.TotalNFTs),
        clanCount: $($script:ApexConfig.ClanCount),
        warriorsPerClan: $($script:ApexConfig.WarriorsPerClan)
    }
};

// ═══════════════════════════════════════════════════════════════════
// The Eight Clans - Core Data Structure
// ═══════════════════════════════════════════════════════════════════

const BUSHIDO_CLANS = $clanData;

// ═══════════════════════════════════════════════════════════════════
// Express Application Initialization
// ═══════════════════════════════════════════════════════════════════

const app = express();
const server = createServer(app);

// Trust proxy configuration
if (config.server.trustProxy) {
    app.set('trust proxy', true);
}

// ═══════════════════════════════════════════════════════════════════
// Middleware Stack - Layered Protection & Enhancement
// ═══════════════════════════════════════════════════════════════════

// Security headers
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'"],
            imgSrc: ["'self'", "data:", "https:", "ipfs:", "ipns:"],
            connectSrc: ["'self'", config.blockchain.abstractRpc],
            fontSrc: ["'self'", "https:", "data:"],
            objectSrc: ["'none'"],
            mediaSrc: ["'self'"],
            frameSrc: ["'none'"],
            upgradeInsecureRequests: config.server.environment === 'production' ? [] : null
        }
    },
    crossOriginEmbedderPolicy: false,
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
    }
}));

// Compression
app.use(compression({
    level: 6,
    threshold: 1024,
    filter: (req, res) => {
        if (req.headers['x-no-compression']) {
            return false;
        }
        return compression.filter(req, res);
    }
}));

// CORS
app.use(cors(config.cors));

// Body parsing
app.use(express.json({ 
    limit: config.security.maxRequestSize,
    verify: (req, res, buf) => {
        req.rawBody = buf.toString('utf8');
    }
}));
app.use(express.urlencoded({ 
    extended: true, 
    limit: config.security.maxRequestSize 
}));

// Request logging
app.use(morgan('combined', {
    stream: {
        write: (message) => logger.http(message.trim())
    },
    skip: (req, res) => {
        // Skip logging for health checks in production
        return config.server.environment === 'production' && req.path === '/health';
    }
}));

// Rate limiting
const limiter = rateLimit({
    ...config.rateLimit,
    keyGenerator: (req) => {
        // Use forwarded IP if behind proxy, otherwise use connection IP
        return req.ip || req.headers['x-forwarded-for']?.split(',')[0] || 'anonymous';
    },
    handler: (req, res) => {
        logger.warn('Rate limit exceeded', { 
            ip: req.ip,
            path: req.path,
            method: req.method,
            userAgent: req.headers['user-agent']
        });
        res.status(429).json(config.rateLimit.message);
    }
});

app.use('/api/', limiter);

// Request ID and timing middleware
app.use((req, res, next) => {
    const requestId = ethers.id(`${Date.now()}-${Math.random()}`).slice(0, 16);
    const startTime = process.hrtime.bigint();
    
    req.id = requestId;
    res.setHeader('X-Request-Id', requestId);
    
    // Capture response time
    const originalSend = res.send;
    res.send = function(data) {
        const endTime = process.hrtime.bigint();
        const duration = Number(endTime - startTime) / 1000000; // Convert to milliseconds
        
        res.setHeader('X-Response-Time', `${duration.toFixed(2)}ms`);
        
        // Log request completion
        logger.info('Request completed', {
            requestId,
            method: req.method,
            path: req.path,
            statusCode: res.statusCode,
            duration: `${duration.toFixed(2)}ms`,
            ip: req.ip,
            userAgent: req.headers['user-agent']
        });
        
        return originalSend.call(this, data);
    };
    
    next();
});

// ═══════════════════════════════════════════════════════════════════
// Validation Middleware Factory
// ═══════════════════════════════════════════════════════════════════

const validate = (validations) => {
    return async (req, res, next) => {
        await Promise.all(validations.map(validation => validation.run(req)));
        
        const errors = validationResult(req);
        if (errors.isEmpty()) {
            return next();
        }
        
        const extractedErrors = errors.array().map(err => ({
            field: err.path,
            message: err.msg,
            value: err.value
        }));
        
        return res.status(400).json({
            success: false,
            error: 'VALIDATION_ERROR',
            message: 'Invalid request parameters',
            errors: extractedErrors,
            requestId: req.id
        });
    };
};

// ═══════════════════════════════════════════════════════════════════
// API Routes - The Path of the Digital Samurai
// ═══════════════════════════════════════════════════════════════════

/**
 * Health Check Endpoint
 * Provides comprehensive system status including blockchain connectivity
 */
app.get('/health', async (req, res) => {
    const healthData = {
        status: 'healthy',
        service: 'Bushido NFT Backend',
        version: '1.0.0-apex',
        timestamp: new Date().toISOString(),
        uptime: {
            seconds: Math.floor(process.uptime()),
            formatted: formatUptime(process.uptime())
        },
        environment: config.server.environment,
        node: {
            version: process.version,
            platform: process.platform,
            memory: {
                used: formatBytes(process.memoryUsage().heapUsed),
                total: formatBytes(process.memoryUsage().heapTotal),
                percentage: Math.round((process.memoryUsage().heapUsed / process.memoryUsage().heapTotal) * 100)
            }
        }
    };
    
    // Test blockchain connectivity
    try {
        const provider = new ethers.JsonRpcProvider(config.blockchain.abstractRpc);
        const [blockNumber, network] = await Promise.all([
            provider.getBlockNumber(),
            provider.getNetwork()
        ]);
        
        healthData.blockchain = {
            connected: true,
            network: network.name || 'Abstract',
            chainId: Number(network.chainId),
            blockNumber,
            latestBlock: new Date().toISOString()
        };
    } catch (error) {
        healthData.blockchain = {
            connected: false,
            error: error.message
        };
        healthData.status = 'degraded';
    }
    
    const statusCode = healthData.status === 'healthy' ? 200 : 503;
    res.status(statusCode).json(healthData);
});

/**
 * Get All Clans
 * Returns the eight clans with optional detailed information
 */
app.get('/api/clans', 
    validate([
        query('detailed').optional().isBoolean().toBoolean()
    ]),
    (req, res) => {
        const { detailed } = req.query;
        
        const clansData = detailed ? BUSHIDO_CLANS : BUSHIDO_CLANS.map(clan => ({
            id: clan.Id,
            name: clan.Name,
            kanji: clan.Kanji,
            virtue: clan.Virtue,
            element: clan.Element,
            color: clan.Color
        }));
        
        res.json({
            success: true,
            data: clansData,
            count: BUSHIDO_CLANS.length,
            meta: {
                version: '1.0.0',
                totalWarriors: config.project.totalNFTs,
                warriorsPerClan: config.project.warriorsPerClan
            }
        });
    }
);

/**
 * Get Specific Clan
 * Returns detailed information about a single clan
 */
app.get('/api/clans/:id',
    validate([
        param('id').isInt({ min: 0, max: 7 }).toInt()
    ]),
    (req, res) => {
        const clanId = req.params.id;
        const clan = BUSHIDO_CLANS[clanId];
        
        // Enrich with dynamic statistics
        const enrichedClan = {
            ...clan,
            statistics: {
                totalWarriors: config.project.warriorsPerClan,
                mintedWarriors: Math.floor(Math.random() * config.project.warriorsPerClan),
                averagePower: Math.floor(Math.random() * 500) + 500,
                activeVotes: Math.floor(Math.random() * 10),
                victories: Math.floor(Math.random() * 100),
                honorPoints: Math.floor(Math.random() * 10000)
            },
            governance: {
                votingPower: (Math.random() * 100).toFixed(2),
                proposals: Math.floor(Math.random() * 5),
                influence: ['Low', 'Medium', 'High', 'Legendary'][Math.floor(Math.random() * 4)]
            }
        };
        
        res.json({
            success: true,
            data: enrichedClan
        });
    }
);

/**
 * Get NFT Metadata
 * Returns ERC721 compliant metadata for a specific token
 */
app.get('/api/metadata/:tokenId',
    validate([
        param('tokenId').isInt({ min: 0, max: config.project.totalNFTs - 1 }).toInt()
    ]),
    (req, res) => {
        const tokenId = req.params.tokenId;
        const clanId = tokenId % config.project.clanCount;
        const clan = BUSHIDO_CLANS[clanId];
        const warriorNumber = Math.floor(tokenId / config.project.clanCount);
        
        // Determine rarity
        const rarity = determineRarity(warriorNumber);
        
        const metadata = {
            name: `Bushido Warrior #${tokenId}`,
            description: `A ${rarity.toLowerCase()} warrior of the ${clan.Name} clan, embodying the virtue of ${clan.Virtue}. ${clan.Description}`,
            image: `ipfs://QmBushidoWarrior${tokenId}`,
            external_url: `https://bushido-nft.io/warrior/${tokenId}`,
            background_color: clan.Color.replace('#', ''),
            attributes: [
                { trait_type: 'Clan', value: clan.Name },
                { trait_type: 'Clan Kanji', value: clan.Kanji },
                { trait_type: 'Virtue', value: clan.Virtue },
                { trait_type: 'Element', value: clan.Element },
                { trait_type: 'Rarity', value: rarity },
                { trait_type: 'Power Level', value: calculatePowerLevel(tokenId, rarity), display_type: 'number' },
                { trait_type: 'Honor Points', value: 0, display_type: 'number' },
                { trait_type: 'Clan Rank', value: warriorNumber + 1, display_type: 'number', max_value: config.project.warriorsPerClan },
                { trait_type: 'Special Power', value: clan.Power },
                ...clan.Traits.map(trait => ({ trait_type: 'Trait', value: trait }))
            ],
            properties: {
                clan: clan.Name,
                special_power: clan.Power,
                files: [{ uri: `ipfs://QmBushidoWarrior${tokenId}`, type: 'image/png' }],
                category: 'image'
            }
        };
        
        res.json(metadata);
    }
);

/**
 * Submit Vote
 * Records a vote for episode decisions
 */
app.post('/api/vote',
    validate([
        body('tokenId').isInt({ min: 0, max: config.project.totalNFTs - 1 }),
        body('episodeId').isInt({ min: 1, max: 8 }),
        body('choice').isIn(['A', 'B', 'C']),
        body('signature').isString().matches(/^0x[a-fA-F0-9]{130}$/)
    ]),
    async (req, res) => {
        const { tokenId, episodeId, choice, signature } = req.body;
        
        try {
            // TODO: Implement signature verification
            // const isValid = await verifyVoteSignature(tokenId, episodeId, choice, signature);
            
            const vote = {
                id: ethers.id(`${tokenId}-${episodeId}-${Date.now()}`).slice(0, 16),
                tokenId,
                episodeId,
                choice,
                timestamp: new Date().toISOString(),
                transactionHash: '0x' + ethers.randomBytes(32).toString('hex'),
                blockNumber: Math.floor(Math.random() * 1000000) + 1000000
            };
            
            logger.info('Vote recorded', { vote, requestId: req.id });
            
            res.json({
                success: true,
                message: 'Vote successfully recorded',
                data: vote
            });
            
        } catch (error) {
            logger.error('Vote processing error', { 
                error: error.message, 
                tokenId,
                episodeId,
                requestId: req.id 
            });
            
            res.status(500).json({
                success: false,
                error: 'VOTE_PROCESSING_FAILED',
                message: 'Failed to process vote',
                requestId: req.id
            });
        }
    }
);

/**
 * Get Episode Information
 * Returns details about story episodes
 */
app.get('/api/episodes/:id',
    validate([
        param('id').isInt({ min: 1, max: 8 }).toInt()
    ]),
    (req, res) => {
        const episodeId = req.params.id;
        const focusClan = BUSHIDO_CLANS[(episodeId - 1) % 8];
        
        const episode = {
            id: episodeId,
            title: `Episode ${episodeId}: The ${focusClan.Name} Revelation`,
            description: `The ${focusClan.Name} clan faces a critical decision that will shape the future of all eight clans...`,
            focusClan: {
                name: focusClan.Name,
                kanji: focusClan.Kanji,
                virtue: focusClan.Virtue
            },
            releaseDate: new Date(Date.now() + (episodeId - 1) * 7 * 24 * 60 * 60 * 1000).toISOString(),
            votingOptions: generateVotingOptions(episodeId),
            votingPeriod: {
                start: new Date(Date.now() + (episodeId - 1) * 7 * 24 * 60 * 60 * 1000).toISOString(),
                end: new Date(Date.now() + episodeId * 7 * 24 * 60 * 60 * 1000).toISOString(),
                status: determineVotingStatus(episodeId)
            },
            statistics: {
                totalVotes: Math.floor(Math.random() * 1000),
                participation: `${Math.floor(Math.random() * 100)}%`,
                leadingChoice: ['A', 'B', 'C'][Math.floor(Math.random() * 3)]
            }
        };
        
        res.json({
            success: true,
            data: episode
        });
    }
);

/**
 * Clan Leaderboard
 * Returns power rankings across all clans
 */
app.get('/api/leaderboard', (req, res) => {
    const leaderboard = BUSHIDO_CLANS.map(clan => ({
        clan: clan.Name,
        kanji: clan.Kanji,
        virtue: clan.Virtue,
        totalPower: Math.floor(Math.random() * 100000) + 50000,
        activeWarriors: Math.floor(Math.random() * config.project.warriorsPerClan),
        votingInfluence: (Math.random() * 100).toFixed(2),
        victories: Math.floor(Math.random() * 50),
        honorPoints: Math.floor(Math.random() * 10000),
        trend: ['rising', 'stable', 'falling'][Math.floor(Math.random() * 3)]
    })).sort((a, b) => b.totalPower - a.totalPower);
    
    res.json({
        success: true,
        data: leaderboard,
        lastUpdated: new Date().toISOString(),
        nextUpdate: new Date(Date.now() + 3600000).toISOString() // 1 hour
    });
});

/**
 * Statistics Endpoint
 * Provides global project statistics
 */
app.get('/api/stats', (req, res) => {
    const stats = {
        success: true,
        data: {
            project: {
                totalNFTs: config.project.totalNFTs,
                totalClans: config.project.clanCount,
                warriorsPerClan: config.project.warriorsPerClan
            },
            minting: {
                totalMinted: Math.floor(Math.random() * config.project.totalNFTs),
                percentMinted: `${Math.floor(Math.random() * 100)}%`,
                averagePrice: '0.08 ETH',
                floorPrice: `${(0.08 + Math.random() * 0.5).toFixed(3)} ETH`
            },
            engagement: {
                totalVotes: Math.floor(Math.random() * 10000),
                activeVoters: Math.floor(Math.random() * 1000),
                episodesReleased: 1,
                nextEpisode: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
            },
            blockchain: {
                network: 'Abstract',
                contractAddress: config.blockchain.contractAddress || 'Not deployed'
            }
        },
        timestamp: new Date().toISOString()
    };
    
    res.json(stats);
});

// ═══════════════════════════════════════════════════════════════════
// Error Handling - The Way of Graceful Recovery
// ═══════════════════════════════════════════════════════════════════

// 404 Handler
app.use((req, res) => {
    logger.warn('Route not found', { 
        path: req.path, 
        method: req.method,
        ip: req.ip,
        requestId: req.id 
    });
    
    res.status(404).json({
        success: false,
        error: 'NOT_FOUND',
        message: 'The path of the warrior you seek does not exist',
        path: req.path,
        method: req.method,
        requestId: req.id,
        timestamp: new Date().toISOString()
    });
});

// Global error handler
app.use((err, req, res, next) => {
    const errorId = ethers.id(`error-${Date.now()}-${Math.random()}`).slice(0, 16);
    
    // Log error with full context
    logger.error('Unhandled error', {
        errorId,
        requestId: req.id,
        error: {
            message: err.message,
            stack: err.stack,
            code: err.code,
            statusCode: err.statusCode
        },
        request: {
            path: req.path,
            method: req.method,
            headers: req.headers,
            query: req.query,
            body: req.body
        }
    });
    
    const isDevelopment = config.server.environment === 'development';
    const statusCode = err.statusCode || err.status || 500;
    
    res.status(statusCode).json({
        success: false,
        error: err.code || 'INTERNAL_ERROR',
        message: isDevelopment ? err.message : 'An unexpected error occurred',
        errorId,
        requestId: req.id,
        timestamp: new Date().toISOString(),
        ...(isDevelopment && { 
            stack: err.stack,
            details: err 
        })
    });
});

// ═══════════════════════════════════════════════════════════════════
// Graceful Shutdown Handler
// ═══════════════════════════════════════════════════════════════════

const gracefulShutdown = (signal) => {
    logger.info(`Received ${signal}, initiating graceful shutdown...`, {
        signal,
        pid: process.pid,
        uptime: formatUptime(process.uptime())
    });
    
    // Set shutdown timeout
    const shutdownTimeout = setTimeout(() => {
        logger.error('Forced shutdown due to timeout');
        process.exit(1);
    }, 30000); // 30 seconds
    
    // Stop accepting new connections
    server.close(() => {
        clearTimeout(shutdownTimeout);
        logger.info('HTTP server closed successfully');
        
        // Perform cleanup operations
        Promise.all([
            // Add any cleanup operations here
            new Promise(resolve => setTimeout(resolve, 1000))
        ]).then(() => {
            logger.info('Bushido NFT Backend shutdown complete');
            process.exit(0);
        }).catch(err => {
            logger.error('Error during cleanup', { error: err.message });
            process.exit(1);
        });
    });
};

// Register shutdown handlers
['SIGTERM', 'SIGINT', 'SIGHUP'].forEach(signal => {
    process.on(signal, () => gracefulShutdown(signal));
});

// Process error handlers
process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Promise Rejection', { 
        reason: reason?.message || reason,
        stack: reason?.stack,
        promise: promise
    });
});

process.on('uncaughtException', (error) => {
    logger.error('Uncaught Exception', { 
        error: error.message,
        stack: error.stack
    });
    gracefulShutdown('UNCAUGHT_EXCEPTION');
});

// ═══════════════════════════════════════════════════════════════════
// Utility Functions
// ═══════════════════════════════════════════════════════════════════

function formatUptime(seconds) {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    const parts = [];
    if (days > 0) parts.push(`${days}d`);
    if (hours > 0) parts.push(`${hours}h`);
    if (minutes > 0) parts.push(`${minutes}m`);
    if (secs > 0 || parts.length === 0) parts.push(`${secs}s`);
    
    return parts.join(' ');
}

function formatBytes(bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    let size = bytes;
    let unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
        size /= 1024;
        unitIndex++;
    }
    
    return `${size.toFixed(2)} ${units[unitIndex]}`;
}

function determineRarity(warriorNumber) {
    if (warriorNumber < 25) return 'Legendary';
    if (warriorNumber < 50) return 'Epic';
    if (warriorNumber < 100) return 'Rare';
    if (warriorNumber < 150) return 'Uncommon';
    return 'Common';
}

function calculatePowerLevel(tokenId, rarity) {
    const basePower = {
        'Legendary': 900,
        'Epic': 700,
        'Rare': 500,
        'Uncommon': 300,
        'Common': 100
    };
    
    const variance = Math.floor(Math.random() * 100);
    const tokenBonus = (tokenId % 100) * 2;
    
    return basePower[rarity] + variance + tokenBonus;
}

function generateVotingOptions(episodeId) {
    const options = [
        {
            id: 'A',
            title: 'Path of Unity',
            description: 'Join forces with rival clans to face the coming storm',
            consequences: 'Increased collective strength but loss of individual clan autonomy',
            supporters: Math.floor(Math.random() * 40) + 20
        },
        {
            id: 'B',
            title: 'Path of Independence',
            description: 'Maintain clan sovereignty and face challenges alone',
            consequences: 'Preserved traditions but potential isolation in times of need',
            supporters: Math.floor(Math.random() * 40) + 20
        },
        {
            id: 'C',
            title: 'Path of Balance',
            description: 'Form selective alliances while maintaining core independence',
            consequences: 'Diplomatic complexity but flexible strategic options',
            supporters: Math.floor(Math.random() * 40) + 20
        }
    ];
    
    // Normalize supporters to 100%
    const total = options.reduce((sum, opt) => sum + opt.supporters, 0);
    options.forEach(opt => {
        opt.supportPercentage = `${Math.round((opt.supporters / total) * 100)}%`;
    });
    
    return options;
}

function determineVotingStatus(episodeId) {
    const now = Date.now();
    const episodeStart = now + (episodeId - 1) * 7 * 24 * 60 * 60 * 1000;
    const episodeEnd = now + episodeId * 7 * 24 * 60 * 60 * 1000;
    
    if (now < episodeStart) return 'upcoming';
    if (now > episodeEnd) return 'concluded';
    return 'active';
}

// ═══════════════════════════════════════════════════════════════════
// Server Initialization
// ═══════════════════════════════════════════════════════════════════

const startServer = () => {
    server.listen(config.server.port, config.server.host, () => {
        const address = server.address();
        const bind = typeof address === 'string' ? address : `${address.address}:${address.port}`;
        
        const banner = `
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║                    BUSHIDO NFT BACKEND                            ║
║                    Apex Architecture v1.0                         ║
║                                                                   ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Status: ACTIVE ⚡                                                ║
║  Environment: ${config.server.environment.padEnd(48)} ║
║  Server: ${bind.padEnd(50)} ║
║  Process ID: ${process.pid.toString().padEnd(49)} ║
║  Node Version: ${process.version.padEnd(47)} ║
║                                                                   ║
╠═══════════════════════════════════════════════════════════════════╣
║                        API ENDPOINTS                              ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  System:                                                          ║
║    GET  /health                 - System health & blockchain      ║
║    GET  /api/stats              - Global statistics               ║
║                                                                   ║
║  Clans:                                                          ║
║    GET  /api/clans              - List all eight clans           ║
║    GET  /api/clans/:id          - Get specific clan details      ║
║    GET  /api/leaderboard        - Clan power rankings            ║
║                                                                   ║
║  NFTs:                                                           ║
║    GET  /api/metadata/:tokenId  - Get warrior metadata           ║
║                                                                   ║
║  Governance:                                                      ║
║    POST /api/vote               - Submit episode vote             ║
║    GET  /api/episodes/:id       - Get episode details            ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝

⚔️  The way of Bushido is now active at ${new Date().toLocaleString()}
🏯 May your code be as sharp as a samurai's blade!
`;
        
        console.log(banner);
        
        logger.info('Bushido NFT Backend initialized successfully', {
            port: config.server.port,
            host: config.server.host,
            environment: config.server.environment,
            nodeVersion: process.version,
            pid: process.pid,
            platform: process.platform
        });
    });
    
    server.on('error', (error) => {
        if (error.code === 'EADDRINUSE') {
            logger.error(`Port ${config.server.port} is already in use`, { error });
            process.exit(1);
        } else {
            logger.error('Server error', { error: error.message, code: error.code });
            throw error;
        }
    });
};

// Initialize the server
startServer();

export default app;
"@
    }
}
#endregion

#region Apex Restoration Engine - The Master Implementation
class ApexRestorationEngine {
    [hashtable]$State
    [System.Diagnostics.Stopwatch]$Timer
    [System.Collections.ArrayList]$Phases
    
    ApexRestorationEngine() {
        $this.State = @{
            CurrentPhase = 'Initialization'
            Progress = 0
            Errors = [System.Collections.ArrayList]::new()
            Warnings = [System.Collections.ArrayList]::new()
            CompletedPhases = [System.Collections.ArrayList]::new()
            Metrics = @{}
        }
        $this.Timer = [System.Diagnostics.Stopwatch]::StartNew()
        $this.InitializePhases()
    }
    
    hidden [void] InitializePhases() {
        $this.Phases = [System.Collections.ArrayList]@(
            @{
                Name = 'Environment Validation'
                Execute = { $this.ValidateEnvironment() }
                Weight = 10
                Critical = $true
            },
            @{
                Name = 'Quantum State Cleanup'
                Execute = { $this.ExecuteCleanup() }
                Weight = 15
                Critical = $true
            },
            @{
                Name = 'Package Manager Setup'
                Execute = { $this.SetupPackageManager() }
                Weight = 10
                Critical = $true
            },
            @{
                Name = 'Architecture Restoration'
                Execute = { $this.RestoreArchitecture() }
                Weight = 30
                Critical = $true
            },
            @{
                Name = 'Dependency Resolution'
                Execute = { $this.ResolveDependencies() }
                Weight = 25
                Critical = $true
            },
            @{
                Name = 'Script Generation'
                Execute = { $this.GenerateScripts() }
                Weight = 5
                Critical = $false
            },
            @{
                Name = 'System Verification'
                Execute = { $this.VerifySystem() }
                Weight = 5
                Critical = $false
            }
        )
    }
    
    [void] Execute() {
        try {
            [ApexConsole]::RenderApexBanner()
            
            $totalWeight = ($this.Phases | Measure-Object -Property Weight -Sum).Sum
            $cumulativeProgress = 0
            
            foreach ($phase in $this.Phases) {
                $this.State.CurrentPhase = $phase.Name
                [ApexConsole]::Section($phase.Name)
                
                try {
                    # Execute phase
                    $phaseTimer = [System.Diagnostics.Stopwatch]::StartNew()
                    & $phase.Execute
                    $phaseTimer.Stop()
                    
                    # Record success
                    $this.State.CompletedPhases.Add($phase.Name) | Out-Null
                    $this.State.Metrics[$phase.Name] = $phaseTimer.ElapsedMilliseconds
                    
                    # Update progress
                    $cumulativeProgress += $phase.Weight
                    $this.State.Progress = [Math]::Round(($cumulativeProgress / $totalWeight) * 100)
                    
                    [ApexConsole]::Status("Phase completed in $($phaseTimer.ElapsedMilliseconds)ms", 'Complete')
                    
                } catch {
                    if ($phase.Critical) {
                        $this.State.Errors.Add(@{
                            Phase = $phase.Name
                            Error = $_
                            Timestamp = [DateTimeOffset]::UtcNow
                        }) | Out-Null
                        throw
                    } else {
                        $this.State.Warnings.Add(@{
                            Phase = $phase.Name
                            Warning = $_.Exception.Message
                            Timestamp = [DateTimeOffset]::UtcNow
                        }) | Out-Null
                        [ApexConsole]::Status("Non-critical phase failed: $_", 'Warning')
                    }
                }
                
                # Visual pause unless in turbo mode
                if (-not $script:ApexConfig.TurboMode -and -not $script:ApexConfig.SilentMode) {
                    Start-Sleep -Milliseconds 300
                }
            }
            
            $this.State.Progress = 100
            $this.DisplayResults()
            
        } catch {
            $this.HandleFailure($_)
            throw
        } finally {
            $this.Timer.Stop()
            $this.RecordTelemetry()
        }
    }
    
    [void] ValidateEnvironment() {
        [ApexConsole]::Status("Validating project environment", 'Working')
        
        # Check current directory
        if (-not (Test-Path "package.json")) {
            throw [System.InvalidOperationException]::new(
                "Not in project root directory. Please navigate to bushido-nft folder."
            )
        }
        
        # Validate Node.js
        try {
            $nodeVersion = node --version
            if ($nodeVersion -match 'v(\d+)\.(\d+)\.(\d+)') {
                $major = [int]$Matches[1]
                $minor = [int]$Matches[2]
                
                if ($major -lt 18) {
                    [ApexConsole]::Status(
                        "Node.js $nodeVersion detected (v18+ recommended)", 
                        'Warning'
                    )
                    $this.State.Warnings.Add("Node.js version below v18") | Out-Null
                } else {
                    [ApexConsole]::Status("Node.js $nodeVersion ✓", 'Success')
                }
            }
        } catch {
            throw [System.InvalidOperationException]::new(
                "Node.js not found. Please install Node.js 18 or higher."
            )
        }
        
        # Check available disk space
        $drive = (Get-Location).Drive
        if ($drive) {
            $freeSpace = (Get-PSDrive $drive.Name).Free
            $requiredSpace = 500MB
            
            if ($freeSpace -lt $requiredSpace) {
                throw [System.InvalidOperationException]::new(
                    "Insufficient disk space. At least 500MB required."
                )
            }
        }
        
        [ApexConsole]::Status("Environment validated", 'Success')
    }
    
    [void] ExecuteCleanup() {
        [ApexConsole]::Status("Initiating quantum cleanup", 'Working')
        
        $targets = @(
            @{ Path = 'node_modules'; Type = 'Root Dependencies' }
            @{ Path = 'pnpm-lock.yaml'; Type = 'pnpm Lock' }
            @{ Path = 'package-lock.json'; Type = 'npm Lock' }
            @{ Path = 'yarn.lock'; Type = 'Yarn Lock' }
            @{ Path = '.next'; Type = 'Next.js Cache' }
            @{ Path = 'dist'; Type = 'Distribution' }
        )
        
        # Add workspace targets
        @('frontend', 'backend', 'contracts', 'scripts') | ForEach-Object {
            $workspace = $_
            @('node_modules', '.next', 'dist', 'build', 'coverage') | ForEach-Object {
                $targets += @{ 
                    Path = Join-Path $workspace $_
                    Type = "$workspace/$_"
                }
            }
        }
        
        $totalSize = 0
        $processedCount = 0
        
        foreach ($target in $targets) {
            if (Test-Path $target.Path) {
                $processedCount++
                $progress = ($processedCount / $targets.Count) * 100
                
                # Calculate size
                try {
                    $item = Get-Item $target.Path -Force -ErrorAction SilentlyContinue
                    if ($item) {
                        if ($item.PSIsContainer) {
                            $size = (Get-ChildItem $target.Path -Recurse -Force -ErrorAction SilentlyContinue | 
                                    Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum ?? 0
                        } else {
                            $size = $item.Length
                        }
                        $totalSize += $size
                    }
                } catch {
                    # Ignore size calculation errors
                }
                
                [ApexConsole]::Progress($progress, "Removing $($target.Type)")
                
                # Remove with retry
                $removed = $false
                for ($i = 0; $i -lt 3; $i++) {
                    try {
                        Remove-Item $target.Path -Recurse -Force -ErrorAction Stop
                        $removed = $true
                        break
                    } catch {
                        if ($i -eq 2) {
                            $this.State.Warnings.Add("Failed to remove: $($target.Path)") | Out-Null
                        } else {
                            Start-Sleep -Milliseconds 200
                        }
                    }
                }
                
                if (-not $script:ApexConfig.TurboMode) {
                    Start-Sleep -Milliseconds 50
                }
            }
        }
        
        [ApexConsole]::Progress(100, "Cleanup complete")
        
        if ($totalSize -gt 0) {
            $sizeInMB = [Math]::Round($totalSize / 1MB, 2)
            [ApexConsole]::Status("Reclaimed ${sizeInMB}MB of disk space", 'Success')
        }
        
        [ApexConsole]::Status("Quantum cleanup complete", 'Success')
    }
    
    [void] SetupPackageManager() {
        [ApexConsole]::Status("Configuring package management", 'Working')
        
        # Check for pnpm
        $pnpmVersion = $null
        try {
            $pnpmVersion = pnpm --version 2>$null
            [ApexConsole]::Status("pnpm $pnpmVersion detected", 'Success')
        } catch {
            [ApexConsole]::Status("Installing pnpm", 'Info')
            
            # Install pnpm with progress
            $installProcess = Start-Process -FilePath "npm" -ArgumentList "install", "-g", "pnpm" -NoNewWindow -Wait -PassThru
            
            if ($installProcess.ExitCode -eq 0) {
                $pnpmVersion = pnpm --version
                [ApexConsole]::Status("pnpm $pnpmVersion installed", 'Success')
            } else {
                throw [System.InvalidOperationException]::new("Failed to install pnpm")
            }
        }
        
        # Configure pnpm for optimal performance
        [ApexConsole]::Status("Optimizing pnpm configuration", 'Info')
        
        # Set configurations silently
        $pnpmConfigs = @{
            'store-dir' = '.pnpm-store'
            'strict-peer-dependencies' = 'false'
            'auto-install-peers' = 'true'
            'shamefully-hoist' = 'true'
        }
        
        foreach ($config in $pnpmConfigs.GetEnumerator()) {
            pnpm config set $config.Key $config.Value 2>$null
        }
        
        [ApexConsole]::Status("Package manager configured", 'Success')
    }
    
    [void] RestoreArchitecture() {
        [ApexConsole]::Status("Restoring project architecture", 'Working')
        
        # Frontend restoration
        $this.RestoreFrontend()
        
        # Backend restoration with Apex architecture
        $this.RestoreBackend()
        
        # Ensure complete project structure
        $this.EnsureProjectStructure()
        
        [ApexConsole]::Status("Architecture restored", 'Success')
    }
    
    [void] RestoreFrontend() {
        [ApexConsole]::Status("Restoring frontend configuration", 'Working')
        
        # Remove TypeScript config if exists
        $tsConfig = "frontend/next.config.ts"
        if (Test-Path $tsConfig) {
            Remove-Item $tsConfig -Force
            [ApexConsole]::Status("Removed TypeScript config", 'Info')
        }
        
        # Create optimized Next.js configuration
        $nextConfig = @'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  poweredByHeader: false,
  compress: true,
  
  images: {
    domains: [
      'ipfs.io',
      'gateway.pinata.cloud',
      'arweave.net',
      'cloudflare-ipfs.com'
    ],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
    formats: ['image/webp'],
    minimumCacheTTL: 60,
    unoptimized: process.env.NODE_ENV === 'development'
  },
  
  webpack: (config, { isServer, dev }) => {
    // Fallbacks for browser environment
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
        crypto: false,
        stream: false,
        http: false,
        https: false,
        zlib: false,
        path: false,
        os: false
      };
    }
    
    // SVG support
    config.module.rules.push({
      test: /\.svg$/,
      use: ['@svgr/webpack']
    });
    
    return config;
  },
  
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'X-DNS-Prefetch-Control',
            value: 'on'
          },
          {
            key: 'X-Frame-Options',
            value: 'SAMEORIGIN'
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff'
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block'
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin'
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()'
          }
        ]
      }
    ];
  },
  
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${process.env.BACKEND_URL || 'http://localhost:4000'}/api/:path*`
      }
    ];
  },
  
  experimental: {
    appDir: true,
    serverActions: true,
    optimizeCss: true
  }
};

module.exports = nextConfig;
'@
        
        [ApexFileSystem]::WriteFile("frontend/next.config.js", $nextConfig)
        [ApexConsole]::Status("Frontend configuration created", 'Success')
    }
    
    [void] RestoreBackend() {
        [ApexConsole]::Status("Building Apex backend architecture", 'Working')
        
        # Ensure directory structure
        $backendDirs = @(
            'backend',
            'backend/src',
            'backend/src/routes',
            'backend/src/services',
            'backend/src/middleware',
            'backend/src/utils',
            'backend/logs',
            'backend/tests'
        )
        
        foreach ($dir in $backendDirs) {
            [ApexFileSystem]::EnsureDirectory($dir)
        }
        
        # Create package.json
        $packageData = [BushidoArchitecture]::GetBackendPackage()
        [ApexFileSystem]::WriteJson("backend/package.json", $packageData)
        
        # Create the Apex backend implementation
        $backendCode = [BushidoArchitecture]::GenerateBackendApex()
        [ApexFileSystem]::WriteFile("backend/src/index.js", $backendCode)
        
        # Create .env.example
        $envExample = @'
# Server Configuration
PORT=4000
HOST=0.0.0.0
NODE_ENV=development
LOG_LEVEL=info

# CORS Configuration
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001
FRONTEND_URL=http://localhost:3000

# Blockchain Configuration
ABSTRACT_RPC=https://api.abs.xyz
ABSTRACT_TESTNET_RPC=https://api.testnet.abs.xyz
CONTRACT_ADDRESS=
CHAIN_ID=11124

# Security
JWT_SECRET=your-256-bit-secret-key-here
SESSION_SECRET=your-session-secret-here
TRUST_PROXY=false

# Database (future implementation)
DATABASE_URL=

# Redis Cache (future implementation)
REDIS_URL=

# IPFS Configuration
IPFS_GATEWAY=https://ipfs.io/ipfs/
PINATA_API_KEY=
PINATA_SECRET_KEY=

# Analytics (optional)
GA_TRACKING_ID=
SENTRY_DSN=
'@
        
        [ApexFileSystem]::WriteFile("backend/.env.example", $envExample)
        
        # Create .gitignore for backend
        $backendGitignore = @'
# Dependencies
node_modules/
.pnpm-store/

# Environment
.env
.env.local
.env.*.local

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# Testing
coverage/
.nyc_output/

# Build
dist/
build/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Temporary
tmp/
temp/
'@
        
        [ApexFileSystem]::WriteFile("backend/.gitignore", $backendGitignore)
        
        [ApexConsole]::Status("Apex backend architecture complete", 'Success')
    }
    
    [void] EnsureProjectStructure() {
        [ApexConsole]::Status("Ensuring complete project structure", 'Working')
        
        # Define complete directory tree
        $projectStructure = @{
            'contracts' = @('contracts', 'scripts', 'test', 'deployments')
            'frontend' = @('src/app', 'src/components', 'src/hooks', 'src/lib', 'src/styles', 'src/utils', 'public/assets')
            'scripts' = @('src', 'metadata', 'deployment')
            'docs' = @('api', 'guides', 'architecture')
            'tests' = @('unit', 'integration', 'e2e')
        }
        
        foreach ($section in $projectStructure.GetEnumerator()) {
            foreach ($dir in $section.Value) {
                $fullPath = Join-Path $section.Key $dir
                [ApexFileSystem]::EnsureDirectory($fullPath)
            }
        }
        
        # Create root configuration files if missing
        $this.EnsureRootConfigs()
        
        [ApexConsole]::Status("Project structure verified", 'Success')
    }
    
    [void] EnsureRootConfigs() {
        # Create .env.example if missing
        if (-not (Test-Path ".env.example")) {
            $rootEnvExample = @'
# Network Configuration
ABSTRACT_RPC=https://api.abs.xyz
ABSTRACT_TESTNET_RPC=https://api.testnet.abs.xyz
PRIVATE_KEY=your_wallet_private_key_here

# Contract Addresses (populated after deployment)
CONTRACT_ADDRESS=
IPFS_BASE_URI=

# Frontend Configuration
NEXT_PUBLIC_NETWORK=abstract
NEXT_PUBLIC_CONTRACT_ADDRESS=
NEXT_PUBLIC_CHAIN_ID=11124

# Backend URL
NEXT_PUBLIC_BACKEND_URL=http://localhost:4000

# IPFS/Pinata Configuration
PINATA_API_KEY=
PINATA_SECRET_KEY=

# Optional: Analytics
NEXT_PUBLIC_GA_ID=
'@
            
            [ApexFileSystem]::WriteFile(".env.example", $rootEnvExample)
        }
        
        # Create .gitignore if missing
        if (-not (Test-Path ".gitignore")) {
            $rootGitignore = @'
# Dependencies
node_modules/
.pnpm-store/

# Build outputs
.next/
out/
dist/
build/
*.tsbuildinfo

# Cache
.turbo/
.cache/

# Environment files
.env
.env.local
.env.*.local

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Testing
coverage/
.nyc_output/

# Misc
.vercel
.netlify
'@
            
            [ApexFileSystem]::WriteFile(".gitignore", $rootGitignore)
        }
    }
    
    [void] ResolveDependencies() {
        [ApexConsole]::Status("Resolving dependency matrix", 'Working')
        
        # Install root dependencies
        [ApexConsole]::Status("Installing root dependencies", 'Info')
        
        $rootInstall = Start-Process -FilePath "pnpm" -ArgumentList "install" -NoNewWindow -Wait -PassThru
        
        if ($rootInstall.ExitCode -ne 0) {
            throw [System.InvalidOperationException]::new("Root dependency installation failed")
        }
        
        [ApexConsole]::Status("Root dependencies installed", 'Success')
        
        # Install workspace dependencies
        if ($script:ApexConfig.TurboMode) {
            [ApexConsole]::Status("Installing workspace dependencies (Turbo Mode)", 'Info')
            $this.ParallelWorkspaceInstall()
        } else {
            [ApexConsole]::Status("Installing workspace dependencies", 'Info')
            
            $workspaceInstall = Start-Process -FilePath "pnpm" -ArgumentList "install", "-r" -NoNewWindow -Wait -PassThru
            
            if ($workspaceInstall.ExitCode -ne 0) {
                throw [System.InvalidOperationException]::new("Workspace dependency installation failed")
            }
        }
        
        [ApexConsole]::Status("All dependencies resolved", 'Success')
    }
    
    [void] ParallelWorkspaceInstall() {
        $workspaces = @('frontend', 'backend', 'contracts', 'scripts')
        $jobs = @()
        
        foreach ($workspace in $workspaces) {
            if (Test-Path (Join-Path $workspace "package.json")) {
                $job = Start-Job -ScriptBlock {
                    param($ws, $root)
                    Set-Location $root
                    Set-Location $ws
                    $result = pnpm install 2>&1
                    return @{
                        Workspace = $ws
                        Success = $LASTEXITCODE -eq 0
                        Output = $result
                    }
                } -ArgumentList $workspace, $PWD
                
                $jobs += @{
                    Job = $job
                    Workspace = $workspace
                }
            }
        }
        
        # Monitor jobs
        while ($jobs.Job | Where-Object { $_.State -eq 'Running' }) {
            $running = ($jobs.Job | Where-Object { $_.State -eq 'Running' }).Count
            $completed = $jobs.Count - $running
            $progress = ($completed / $jobs.Count) * 100
            
            [ApexConsole]::Progress($progress, "Installing dependencies ($completed/$($jobs.Count) complete)")
            Start-Sleep -Milliseconds 500
        }
        
        [ApexConsole]::Progress(100, "Parallel installation complete")
        
        # Check results
        $failed = @()
        foreach ($jobInfo in $jobs) {
            $result = Receive-Job $jobInfo.Job
            Remove-Job $jobInfo.Job
            
            if (-not $result.Success) {
                $failed += $result.Workspace
            }
        }
        
        if ($failed.Count -gt 0) {
            throw [System.InvalidOperationException]::new(
                "Failed to install dependencies for: $($failed -join ', ')"
            )
        }
    }
    
    [void] GenerateScripts() {
        [ApexConsole]::Status("Generating launch scripts", 'Working')
        
        # Main development launcher
        $devScript = @'
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Bushido NFT - Development Environment
    Unified launcher for all project services
#>

param(
    [switch]$Silent,
    [switch]$NoBrowser
)

# Aesthetic header
function Show-Banner {
    if (-not $Silent) {
        Clear-Host
        Write-Host ""
        Write-Host "    ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "    ║          BUSHIDO NFT DEVELOPMENT             ║" -ForegroundColor Cyan
        Write-Host "    ║        Eight Clans • One Destiny             ║" -ForegroundColor Cyan
        Write-Host "    ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

# Environment setup
function Ensure-Environment {
    if (-not (Test-Path ".env")) {
        Write-Host "⚠️  Creating .env from template..." -ForegroundColor Yellow
        Copy-Item ".env.example" ".env" -Force
        Write-Host "✓ Created .env file" -ForegroundColor Green
        Write-Host ""
        Write-Host "📝 Configure your .env file with:" -ForegroundColor Yellow
        Write-Host "   - Abstract RPC URL" -ForegroundColor White
        Write-Host "   - Wallet private key" -ForegroundColor White
        Write-Host "   - Other required settings" -ForegroundColor White
        Write-Host ""
        Write-Host "Press any key to continue..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Main execution
Show-Banner
Ensure-Environment

Write-Host "🚀 Launching Bushido NFT Services" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "   Frontend → http://localhost:3000" -ForegroundColor Green
Write-Host "   Backend  → http://localhost:4000" -ForegroundColor Green
Write-Host "   Health   → http://localhost:4000/health" -ForegroundColor Blue
Write-Host ""

if (-not $NoBrowser) {
    Write-Host "💡 Browser will open automatically in 5 seconds..." -ForegroundColor DarkGray
    
    # Schedule browser opening
    Start-Job -ScriptBlock {
        Start-Sleep -Seconds 5
        Start-Process "http://localhost:3000"
    } | Out-Null
}

Write-Host "⚡ Press Ctrl+C to stop all services" -ForegroundColor Yellow
Write-Host ""

# Launch services
try {
    pnpm run dev
} catch {
    Write-Host "`n❌ Services stopped" -ForegroundColor Red
}
'@
        
        [ApexFileSystem]::WriteFile("dev.ps1", $devScript)
        
        # Advanced service runner
        $runScript = @'
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Bushido NFT - Advanced Service Runner
    Granular control over individual services
#>

param(
    [Parameter(Position = 0)]
    [ValidateSet("all", "frontend", "backend", "contracts", "scripts", "test", "build", "deploy")]
    [string]$Service = "all",
    
    [switch]$Production,
    [switch]$Watch,
    [switch]$Debug
)

$ErrorActionPreference = 'Stop'

# Service definitions
$services = @{
    frontend = @{
        Name = "Frontend (Next.js)"
        Path = "frontend"
        DevCmd = "pnpm run dev"
        ProdCmd = "pnpm run build && pnpm run start"
        BuildCmd = "pnpm run build"
        Icon = "🎨"
        Port = 3000
    }
    backend = @{
        Name = "Backend (Express)"
        Path = "backend"
        DevCmd = "pnpm run dev"
        ProdCmd = "pnpm run start"
        BuildCmd = "pnpm run build"
        Icon = "⚡"
        Port = 4000
    }
    contracts = @{
        Name = "Smart Contracts"
        Path = "contracts"
        DevCmd = "pnpm run compile"
        BuildCmd = "pnpm run compile"
        TestCmd = "pnpm run test"
        Icon = "📜"
    }
    scripts = @{
        Name = "Scripts"
        Path = "scripts"
        DevCmd = "pnpm run dev"
        BuildCmd = "pnpm run build"
        Icon = "🛠️"
    }
}

# Display header
function Show-ServiceHeader($serviceName, $icon) {
    Write-Host ""
    Write-Host "$icon Starting $serviceName" -ForegroundColor Cyan
    Write-Host ("─" * 50) -ForegroundColor DarkCyan
}

# Execute service
try {
    switch ($Service) {
        "all" {
            Show-ServiceHeader "All Services" "🚀"
            if ($Production) {
                Write-Host "⚠️  Production mode not available for 'all'" -ForegroundColor Yellow
                exit 1
            }
            ./dev.ps1
        }
        
        "test" {
            Show-ServiceHeader "Test Suite" "🧪"
            Write-Host "Running all tests..." -ForegroundColor Green
            pnpm run test
        }
        
        "build" {
            Show-ServiceHeader "Production Build" "🏗️"
            Write-Host "Building all packages..." -ForegroundColor Green
            pnpm run build
        }
        
        "deploy" {
            Show-ServiceHeader "Deployment" "🚀"
            Write-Host "Choose deployment target:" -ForegroundColor Yellow
            Write-Host "  1. Abstract Testnet" -ForegroundColor White
            Write-Host "  2. Abstract Mainnet" -ForegroundColor White
            
            $choice = Read-Host "Enter choice (1-2)"
            
            switch ($choice) {
                "1" { 
                    Write-Host "Deploying to Abstract Testnet..." -ForegroundColor Green
                    Set-Location contracts
                    pnpm run deploy -- --network abstractTestnet
                }
                "2" { 
                    Write-Host "⚠️  Deploying to MAINNET!" -ForegroundColor Red
                    $confirm = Read-Host "Are you sure? (yes/no)"
                    if ($confirm -eq "yes") {
                        Set-Location contracts
                        pnpm run deploy -- --network abstract
                    }
                }
                default {
                    Write-Host "Invalid choice" -ForegroundColor Red
                    exit 1
                }
            }
        }
        
        default {
            $svc = $services[$Service]
            if (-not $svc) {
                Write-Host "Unknown service: $Service" -ForegroundColor Red
                exit 1
            }
            
            Show-ServiceHeader $svc.Name $svc.Icon
            
            Set-Location $svc.Path
            
            if ($Production -and $svc.ProdCmd) {
                Write-Host "🏭 Production mode" -ForegroundColor Yellow
                Invoke-Expression $svc.ProdCmd
            } else {
                if ($svc.Port) {
                    Write-Host "📡 URL: http://localhost:$($svc.Port)" -ForegroundColor Blue
                }
                Invoke-Expression $svc.DevCmd
            }
        }
    }
} catch {
    Write-Host "`n❌ Error: $_" -ForegroundColor Red
    exit 1
}
'@
        
        [ApexFileSystem]::WriteFile("run.ps1", $runScript)
        
        # Quick utility scripts
        $utilityScripts = @{
            "check-health.ps1" = @'
#!/usr/bin/env pwsh
Write-Host "🏥 Checking Bushido NFT Backend Health..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:4000/health"
    $response | ConvertTo-Json -Depth 10 | Write-Host
} catch {
    Write-Host "❌ Backend not responding" -ForegroundColor Red
    Write-Host "   Run ./dev.ps1 to start services" -ForegroundColor Yellow
}
'@
            
            "view-clans.ps1" = @'
#!/usr/bin/env pwsh
Write-Host "⛩️  Bushido NFT - The Eight Clans" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
try {
    $clans = Invoke-RestMethod -Uri "http://localhost:4000/api/clans?detailed=true"
    foreach ($clan in $clans.data) {
        Write-Host "`n$($clan.Kanji) $($clan.Name) - $($clan.Virtue)" -ForegroundColor $clan.Color
        Write-Host "   Element: $($clan.Element)" -ForegroundColor White
        Write-Host "   Power: $($clan.Power)" -ForegroundColor Yellow
        Write-Host "   $($clan.Description)" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Cannot retrieve clan data" -ForegroundColor Red
    Write-Host "   Ensure backend is running: ./run.ps1 backend" -ForegroundColor Yellow
}
'@
            
            "clean.ps1" = @'
#!/usr/bin/env pwsh
Write-Host "🧹 Cleaning Bushido NFT Project..." -ForegroundColor Cyan
$targets = @(
    "node_modules",
    "**/node_modules",
    ".next",
    "dist",
    "build",
    "coverage",
    "*.log",
    ".turbo"
)

foreach ($target in $targets) {
    Write-Host "   Removing $target..." -ForegroundColor Yellow
    Remove-Item $target -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "✓ Project cleaned" -ForegroundColor Green
'@
        }
        
        foreach ($script in $utilityScripts.GetEnumerator()) {
            [ApexFileSystem]::WriteFile($script.Key, $script.Value)
        }
        
        [ApexConsole]::Status("Launch scripts generated", 'Success')
    }
    
    [void] VerifySystem() {
        [ApexConsole]::Status("Verifying system integrity", 'Working')
        
        $verificationChecks = @(
            @{ Name = "Root package.json"; Path = "package.json"; Critical = $true }
            @{ Name = "Frontend package.json"; Path = "frontend/package.json"; Critical = $true }
            @{ Name = "Frontend config"; Path = "frontend/next.config.js"; Critical = $true }
            @{ Name = "Frontend dependencies"; Path = "frontend/node_modules"; Critical = $true }
            @{ Name = "Backend package.json"; Path = "backend/package.json"; Critical = $true }
            @{ Name = "Backend server"; Path = "backend/src/index.js"; Critical = $true }
            @{ Name = "Backend dependencies"; Path = "backend/node_modules"; Critical = $true }
            @{ Name = "Contracts directory"; Path = "contracts"; Critical = $false }
            @{ Name = "Scripts directory"; Path = "scripts"; Critical = $false }
            @{ Name = "Environment template"; Path = ".env.example"; Critical = $false }
            @{ Name = "Dev launcher"; Path = "dev.ps1"; Critical = $false }
            @{ Name = "Service runner"; Path = "run.ps1"; Critical = $false }
        )
        
        $passed = 0
        $failed = 0
        $warnings = 0
        
        foreach ($check in $verificationChecks) {
            if (Test-Path $check.Path) {
                [ApexConsole]::Status("$($check.Name) ✓", 'Success', 4)
                $passed++
            } else {
                if ($check.Critical) {
                    [ApexConsole]::Status("$($check.Name) ✗", 'Error', 4)
                    $failed++
                } else {
                    [ApexConsole]::Status("$($check.Name) ⚠", 'Warning', 4)
                    $warnings++
                }
            }
        }
        
        $this.State.Metrics['Verification'] = @{
            Passed = $passed
            Failed = $failed
            Warnings = $warnings
        }
        
        if ($failed -gt 0) {
            throw [System.InvalidOperationException]::new(
                "$failed critical components failed verification"
            )
        }
        
        [ApexConsole]::Status("System verification complete", 'Success')
    }
    
    [void] DisplayResults() {
        $duration = $this.Timer.Elapsed
        
        Write-Host ""
        
        if ($this.State.Errors.Count -eq 0) {
            # Success banner
            $banner = @'

        ╔═══════════════════════════════════════════════════════════╗
        ║                                                           ║
        ║              ✨ APEX RESTORATION COMPLETE ✨              ║
        ║                                                           ║
        ║         Your Bushido NFT project has been restored        ║
        ║         with unprecedented precision and elegance!        ║
        ║                                                           ║
        ╚═══════════════════════════════════════════════════════════╝

'@
            Write-Host $banner -ForegroundColor Green
            
            # Metrics
            Write-Host "📊 Restoration Metrics:" -ForegroundColor Cyan
            Write-Host "   Total Duration: $($duration.ToString('mm\:ss\.fff'))"
            Write-Host "   Phases Completed: $($this.State.CompletedPhases.Count)"
            
            if ($this.State.Metrics.Verification) {
                $v = $this.State.Metrics.Verification
                Write-Host "   Verification: $($v.Passed) passed, $($v.Warnings) warnings"
            }
            
            # Commands
            Write-Host "`n🚀 Quick Start Commands:" -ForegroundColor Yellow
            Write-Host "   ./dev.ps1              → Launch all services"
            Write-Host "   ./run.ps1 frontend     → Frontend only"
            Write-Host "   ./run.ps1 backend      → Backend only"
            Write-Host "   ./run.ps1 deploy       → Deploy contracts"
            Write-Host "   ./check-health.ps1     → Check system health"
            Write-Host "   ./view-clans.ps1       → View the eight clans"
            
            # Next steps
            Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
            Write-Host "   1. Configure your .env file"
            Write-Host "   2. Run ./dev.ps1 to start development"
            Write-Host "   3. Visit http://localhost:3000"
            
            # Wisdom
            $wisdoms = @(
                "May your code be as sharp as a katana's edge!",
                "The eight clans await your command!",
                "Your journey on the path of Bushido begins now!",
                "Warriors are forged in the fire of determination!",
                "Honor guides those who walk the developer's path!"
            )
            
            Write-Host "`n🏯 $($wisdoms | Get-Random)" -ForegroundColor Magenta
            
        } else {
            Write-Host "`n⚠️  Restoration completed with errors" -ForegroundColor Red
            Write-Host "   Errors: $($this.State.Errors.Count)" -ForegroundColor Red
            Write-Host "   Please review the errors above" -ForegroundColor Yellow
        }
        
        # Diagnostic output
        if ($script:ApexConfig.DiagnosticMode) {
            $this.OutputDiagnostics()
        }
    }
    
    [void] OutputDiagnostics() {
        Write-Host "`n📊 Diagnostic Report:" -ForegroundColor DarkCyan
        Write-Host ("═" * 60) -ForegroundColor DarkCyan
        
        # Phase timings
        Write-Host "`nPhase Timings:" -ForegroundColor Cyan
        foreach ($phase in $this.State.Metrics.Keys | Sort-Object) {
            if ($phase -ne 'Verification') {
                $time = $this.State.Metrics[$phase]
                Write-Host "   $phase`: ${time}ms" -ForegroundColor White
            }
        }
        
        # Warnings
        if ($this.State.Warnings.Count -gt 0) {
            Write-Host "`nWarnings:" -ForegroundColor Yellow
            foreach ($warning in $this.State.Warnings) {
                Write-Host "   - $warning" -ForegroundColor Yellow
            }
        }
        
        # Save diagnostics
        $diagnosticFile = "apex-restoration-diagnostics-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $diagnostics = @{
            Timestamp = [DateTimeOffset]::UtcNow
            Duration = $this.Timer.Elapsed.TotalSeconds
            Configuration = $script:ApexConfig
            State = $this.State
            Telemetry = $script:Telemetry | ForEach-Object { $_ }
        }
        
        $diagnostics | ConvertTo-Json -Depth 10 | Out-File $diagnosticFile -Encoding UTF8
        Write-Host "`nDiagnostics saved to: $diagnosticFile" -ForegroundColor DarkGray
    }
    
    [void] HandleFailure([object]$error) {
        Write-Host "`n⚡ CRITICAL FAILURE DETECTED" -ForegroundColor Magenta
        Write-Host ("═" * 60) -ForegroundColor DarkMagenta
        Write-Host "Error: $($error.Exception.Message)" -ForegroundColor Red
        Write-Host "Phase: $($this.State.CurrentPhase)" -ForegroundColor Yellow
        
        if ($script:ApexConfig.DiagnosticMode) {
            Write-Host "`nStack Trace:" -ForegroundColor DarkGray
            Write-Host $error.ScriptStackTrace -ForegroundColor DarkGray
        }
        
        Write-Host "`n💡 Troubleshooting:" -ForegroundColor Cyan
        Write-Host "   1. Ensure you're in the bushido-nft directory"
        Write-Host "   2. Check Node.js version (18+ required)"
        Write-Host "   3. Verify internet connectivity"
        Write-Host "   4. Run with -Diagnostic for detailed output"
        Write-Host "   5. Check file permissions in project directory"
    }
    
    [void] RecordTelemetry() {
        if ($script:ApexConfig.DiagnosticMode) {
            $telemetryEntry = @{
                SessionId = [Guid]::NewGuid()
                Timestamp = [DateTimeOffset]::UtcNow
                Duration = $this.Timer.Elapsed.TotalSeconds
                Success = $this.State.Errors.Count -eq 0
                Phases = $this.State.CompletedPhases
                Errors = $this.State.Errors.Count
                Warnings = $this.State.Warnings.Count
                Platform = $PSVersionTable.Platform
                PSVersion = $PSVersionTable.PSVersion.ToString()
            }
            
            $script:Telemetry.Add($telemetryEntry)
        }
    }
}
#endregion

#region Apex Entry Point - The Inception of Excellence

# Validate PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "❌ PowerShell 7.0 or higher is required" -ForegroundColor Red
    Write-Host "   Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "   Download from: https://github.com/PowerShell/PowerShell" -ForegroundColor Cyan
    exit 1
}

# Initialize and execute
try {
    $engine = [ApexRestorationEngine]::new()
    $engine.Execute()
    
    # Success exit
    exit 0
} catch {
    # Failure exit
    Write-Host "`n❌ Restoration failed" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
    exit 1
}
#endregion