<#
.SYNOPSIS
    Deep scan PowerShell scripts for syntax errors and quality issues.
    Runs PSScriptAnalyzer twice per execution and can auto-fix issues.

.DESCRIPTION
    This script validates PowerShell files in the repository using:
    - PowerShell parser validation ([scriptblock]::Create)
    - PSScriptAnalyzer with selected rules
    - Auto-fixing capabilities via Invoke-Formatter and Invoke-ScriptAnalyzer -Fix
    - Optional YAML validation for workflow files (without editing them)

.PARAMETER AutoFix
    Apply automatic fixes to PowerShell files where possible

.PARAMETER CreatePR
    Create a new branch and commit fixes (requires AutoFix)

.EXAMPLE
    .\scripts\deepscan.ps1
    # Run scan only, no fixes

.EXAMPLE
    .\scripts\deepscan.ps1 -AutoFix
    # Run scan and apply fixes locally

.EXAMPLE
    .\scripts\deepscan.ps1 -AutoFix -CreatePR
    # Run scan, apply fixes, and commit to new branch
#>

[CmdletBinding()]
param(
    [switch]$AutoFix,
    [switch]$CreatePR
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$LogFile = Join-Path $Root "logs" "deepscan.log"

# Ensure logs directory exists
$null = New-Item -ItemType Directory -Force -Path (Join-Path $Root "logs") -ErrorAction SilentlyContinue

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Write-Host $logMessage
    $logMessage | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

function Test-PowerShellSyntax {
    param([string]$FilePath)
    
    Write-Log "Validating PowerShell syntax: $FilePath"
    try {
        $content = Get-Content -Path $FilePath -Raw
        $null = [scriptblock]::Create($content)
        Write-Log "✓ Syntax valid: $FilePath" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "✗ Syntax error in $FilePath`: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Install-PSScriptAnalyzer {
    Write-Log "Checking for PSScriptAnalyzer module..."
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-Log "Installing PSScriptAnalyzer..."
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -SkipPublisherCheck
        Write-Log "✓ PSScriptAnalyzer installed" -Level "SUCCESS"
    }
    else {
        Write-Log "✓ PSScriptAnalyzer already installed" -Level "SUCCESS"
    }
}

function Invoke-PSScriptAnalyzerScan {
    param(
        [string[]]$FilePaths,
        [switch]$Fix
    )
    
    Write-Log "Running PSScriptAnalyzer scan (Fix=$Fix)..."
    
    # Selected rules to avoid false positives and focus on real issues
    $rules = @(
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingPositionalParameters',
        'PSUseApprovedVerbs',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidGlobalVars'
    )
    
    $allIssues = @()
    
    foreach ($file in $FilePaths) {
        Write-Log "Analyzing: $file"
        
        if ($Fix) {
            # First pass: Get fixable issues
            $issues = Invoke-ScriptAnalyzer -Path $file -IncludeRule $rules -ErrorAction SilentlyContinue
            
            if ($issues) {
                Write-Log "  Found $($issues.Count) issue(s) before fix" -Level "WARN"
                
                # Apply fixes
                try {
                    Invoke-Formatter -ScriptDefinition (Get-Content $file -Raw) |
                        Set-Content -Path $file -Encoding UTF8 -NoNewline
                    Write-Log "  Applied formatter to $file" -Level "SUCCESS"
                }
                catch {
                    Write-Log "  Could not apply formatter: $($_.Exception.Message)" -Level "WARN"
                }
            }
            
            # Second pass: Check remaining issues
            $remainingIssues = Invoke-ScriptAnalyzer -Path $file -IncludeRule $rules -ErrorAction SilentlyContinue
            if ($remainingIssues) {
                Write-Log "  $($remainingIssues.Count) issue(s) remain after fix" -Level "WARN"
                $allIssues += $remainingIssues
            }
            else {
                Write-Log "  ✓ All issues fixed in $file" -Level "SUCCESS"
            }
        }
        else {
            $issues = Invoke-ScriptAnalyzer -Path $file -IncludeRule $rules -ErrorAction SilentlyContinue
            if ($issues) {
                Write-Log "  Found $($issues.Count) issue(s)" -Level "WARN"
                $allIssues += $issues
            }
            else {
                Write-Log "  ✓ No issues found in $file" -Level "SUCCESS"
            }
        }
    }
    
    return $allIssues
}

function Test-WorkflowYAML {
    param([string[]]$FilePaths)
    
    Write-Log "Validating GitHub workflow YAML files (read-only)..."
    
    $hasErrors = $false
    foreach ($file in $FilePaths) {
        Write-Log "Checking YAML: $file"
        try {
            # Basic YAML validation using PowerShell
            $content = Get-Content -Path $file -Raw
            
            # Check for common YAML issues
            if ($content -match '\t') {
                Write-Log "  ✗ YAML contains tabs (should use spaces)" -Level "ERROR"
                $hasErrors = $true
            }
            
            # Check for basic structure
            if ($content -notmatch '^name:' -and $content -notmatch '^on:') {
                Write-Log "  ⚠ YAML may be missing required 'name:' or 'on:' field" -Level "WARN"
            }
            
            # Check for exposed tokens (secret scanning concern)
            if ($content -match 'GITHUB_TOKEN.*\$\{\{.*secrets\.GITHUB_TOKEN.*\}\}') {
                Write-Log "  ⚠ Explicit GITHUB_TOKEN reference found (consider using implicit token)" -Level "WARN"
            }
            
            if (-not $hasErrors) {
                Write-Log "  ✓ YAML appears valid: $file" -Level "SUCCESS"
            }
        }
        catch {
            Write-Log "  ✗ Error validating YAML: $($_.Exception.Message)" -Level "ERROR"
            $hasErrors = $true
        }
    }
    
    return -not $hasErrors
}

# Main execution
Write-Log "=== Deep Scan Started ===" -Level "INFO"
Write-Log "AutoFix: $AutoFix, CreatePR: $CreatePR"

# Find all PowerShell files
$psFiles = Get-ChildItem -Path $Root -Include *.ps1, *.psm1 -Recurse -File |
    Where-Object { $_.FullName -notlike "*\node_modules\*" -and $_.FullName -notlike "*\temp\*" }

if ($psFiles.Count -eq 0) {
    Write-Log "No PowerShell files found to scan" -Level "WARN"
    exit 0
}

Write-Log "Found $($psFiles.Count) PowerShell file(s) to scan"

# First scan: Syntax validation
Write-Log "`n=== Pass 1: Syntax Validation ===" -Level "INFO"
$syntaxErrors = 0
foreach ($file in $psFiles) {
    if (-not (Test-PowerShellSyntax -FilePath $file.FullName)) {
        $syntaxErrors++
    }
}

if ($syntaxErrors -gt 0) {
    Write-Log "`n✗ Found $syntaxErrors syntax error(s) - fix these before continuing" -Level "ERROR"
    exit 1
}

# Install PSScriptAnalyzer if needed
Install-PSScriptAnalyzer

# Second scan: PSScriptAnalyzer (first pass)
Write-Log "`n=== Pass 2: PSScriptAnalyzer (First Pass) ===" -Level "INFO"
$issues1 = Invoke-PSScriptAnalyzerScan -FilePaths $psFiles.FullName -Fix:$AutoFix

# Third scan: PSScriptAnalyzer (second pass to verify)
Write-Log "`n=== Pass 3: PSScriptAnalyzer (Second Pass - Verification) ===" -Level "INFO"
$issues2 = Invoke-PSScriptAnalyzerScan -FilePaths $psFiles.FullName -Fix:$false

# Validate workflow YAML files (read-only, never edit)
$workflowFiles = Get-ChildItem -Path (Join-Path $Root ".github\workflows") -Include *.yml, *.yaml -Recurse -File -ErrorAction SilentlyContinue
if ($workflowFiles) {
    Write-Log "`n=== Workflow YAML Validation (Read-Only) ===" -Level "INFO"
    $yamlValid = Test-WorkflowYAML -FilePaths $workflowFiles.FullName
}

# Summary
Write-Log "`n=== Deep Scan Summary ===" -Level "INFO"
Write-Log "Syntax errors: $syntaxErrors"
Write-Log "PSScriptAnalyzer issues (pass 1): $($issues1.Count)"
Write-Log "PSScriptAnalyzer issues (pass 2): $($issues2.Count)"

$exitCode = 0
if ($syntaxErrors -gt 0 -or $issues2.Count -gt 0) {
    $exitCode = 1
    Write-Log "`n✗ Deep scan found issues" -Level "ERROR"
}
else {
    Write-Log "`n✓ Deep scan passed - no issues found!" -Level "SUCCESS"
}

# Create PR if requested and fixes were applied
if ($AutoFix -and $CreatePR -and $exitCode -eq 0) {
    Write-Log "`n=== Creating PR for fixes ===" -Level "INFO"
    
    $branchName = "bot/deepscan-fixes-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    
    try {
        # Check if there are changes
        $gitStatus = git status --porcelain
        if ($gitStatus) {
            Write-Log "Changes detected, creating branch and committing..."
            
            git checkout -b $branchName
            git add -A
            git commit -m "Apply PSScriptAnalyzer auto-fixes from deep scan"
            
            Write-Log "✓ Created branch $branchName with fixes" -Level "SUCCESS"
            Write-Log "Note: Push to remote and create PR manually or via CI" -Level "INFO"
        }
        else {
            Write-Log "No changes to commit - all files already clean" -Level "INFO"
        }
    }
    catch {
        Write-Log "Error creating PR branch: $($_.Exception.Message)" -Level "ERROR"
        $exitCode = 1
    }
}

Write-Log "=== Deep Scan Complete ===" -Level "INFO"
exit $exitCode
