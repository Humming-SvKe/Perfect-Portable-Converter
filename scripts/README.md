# Scripts Directory

This directory contains maintenance and validation scripts for the Perfect Portable Converter project.

## deepscan.ps1

A comprehensive PowerShell validation script that performs deep analysis of the codebase.

### Features

- **Syntax Validation**: Validates PowerShell syntax using `[scriptblock]::Create`
- **Code Quality**: Runs PSScriptAnalyzer with selected rules
- **Auto-Fix**: Can automatically fix common issues
- **Dual-Pass**: Runs twice to verify fixes are stable
- **YAML Validation**: Validates workflow YAML files (read-only)
- **PR Creation**: Can create automated PRs with fixes

### Usage

```powershell
# Run scan only (no changes)
.\scripts\deepscan.ps1

# Run scan and apply auto-fixes
.\scripts\deepscan.ps1 -AutoFix

# Run scan, fix, and create a new branch for PR
.\scripts\deepscan.ps1 -AutoFix -CreatePR
```

### CI Integration

The script is integrated into the GitHub Actions workflow `.github/workflows/deepscan.yml`:
- Runs automatically on push to main or PRs affecting PowerShell/YAML files
- Executes twice per run to ensure stability
- Auto-creates PRs with fixes on failure (not for PR builds)

### Exit Codes

- `0`: Success - no issues found
- `1`: Failure - issues found that need attention

### Logs

Scan logs are written to `logs/deepscan.log` (automatically ignored by git).
