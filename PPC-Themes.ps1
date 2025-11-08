<# Perfect Portable Converter - Theme Manager Module
   Manages color themes for CLI and GUI interfaces
#>

$global:THEME_CONFIG = "$PSScriptRoot\config\themes.json"
$global:CURRENT_THEME = $null

# Load theme configuration
function Load-ThemeConfig {
    if (Test-Path $global:THEME_CONFIG) {
        try {
            $config = Get-Content $global:THEME_CONFIG -Raw | ConvertFrom-Json
            $global:CURRENT_THEME = $config.themes.($config.current_theme)
            return $config
        } catch {
            Write-Host "WARNING: Failed to load theme config: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    return $null
}

# Save theme configuration
function Save-ThemeConfig {
    param([object]$config)
    
    try {
        $config | ConvertTo-Json -Depth 10 | Set-Content $global:THEME_CONFIG -Encoding UTF8
        return $true
    } catch {
        Write-Host "ERROR: Failed to save theme config: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Set current theme
function Set-Theme {
    param([string]$themeName)
    
    $config = Load-ThemeConfig
    if (-not $config) {
        Write-Host "ERROR: Theme configuration not found" -ForegroundColor Red
        return $false
    }
    
    if (-not $config.themes.$themeName) {
        Write-Host "ERROR: Theme '$themeName' not found" -ForegroundColor Red
        return $false
    }
    
    $config.current_theme = $themeName
    $global:CURRENT_THEME = $config.themes.$themeName
    
    if (Save-ThemeConfig $config) {
        Write-Host "Theme changed to: $($global:CURRENT_THEME.name)" -ForegroundColor Green
        return $true
    }
    
    return $false
}

# Get list of available themes
function Get-AvailableThemes {
    $config = Load-ThemeConfig
    if (-not $config) { return @() }
    
    $themes = @()
    $config.themes.PSObject.Properties | ForEach-Object {
        $themes += @{
            id = $_.Name
            name = $_.Value.name
            type = $_.Value.type
        }
    }
    
    return $themes
}

# Write colored text for CLI
function Write-Themed {
    param(
        [string]$text,
        [string]$colorType = "foreground"
    )
    
    if (-not $global:CURRENT_THEME) {
        Load-ThemeConfig | Out-Null
    }
    
    $color = switch ($colorType) {
        "primary" { $global:CURRENT_THEME.cli.primary }
        "secondary" { $global:CURRENT_THEME.cli.secondary }
        "success" { $global:CURRENT_THEME.cli.success }
        "warning" { $global:CURRENT_THEME.cli.warning }
        "error" { $global:CURRENT_THEME.cli.error }
        "info" { $global:CURRENT_THEME.cli.info }
        default { $global:CURRENT_THEME.cli.foreground }
    }
    
    Write-Host $text -ForegroundColor $color
}

# Apply theme to GUI form
function Apply-GuiTheme {
    param([System.Windows.Forms.Form]$form)
    
    if (-not $global:CURRENT_THEME) {
        Load-ThemeConfig | Out-Null
    }
    
    if (-not $global:CURRENT_THEME) { return }
    
    $theme = $global:CURRENT_THEME.gui
    
    # Apply to form
    $form.BackColor = [System.Drawing.ColorTranslator]::FromHtml($theme.background)
    $form.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($theme.foreground)
    
    # Apply to all controls recursively
    function Apply-ToControl {
        param($control)
        
        foreach ($ctrl in $control.Controls) {
            # Buttons - Enhanced with border and hover
            if ($ctrl -is [System.Windows.Forms.Button]) {
                $ctrl.BackColor = [System.Drawing.ColorTranslator]::FromHtml($theme.button_bg)
                $ctrl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($theme.button_fg)
                $ctrl.FlatStyle = 'Flat'
                
                # Add border for material themes
                if ($theme.PSObject.Properties.Name -contains 'border') {
                    $ctrl.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml($theme.border)
                    $ctrl.FlatAppearance.BorderSize = 1
                }
                
                # Add subtle mouse hover effect
                if ($theme.PSObject.Properties.Name -contains 'accent') {
                    $ctrl.FlatAppearance.MouseOverBackColor = [System.Drawing.ColorTranslator]::FromHtml($theme.accent)
                }
                
                # Add padding for better look
                try {
                    $ctrl.Padding = New-Object System.Windows.Forms.Padding(5, 3, 5, 3)
                } catch {}
            }
            # TextBoxes - Enhanced with border
            elseif ($ctrl -is [System.Windows.Forms.TextBox]) {
                $ctrl.BackColor = [System.Drawing.ColorTranslator]::FromHtml($theme.textbox_bg)
                $ctrl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($theme.textbox_fg)
                $ctrl.BorderStyle = 'FixedSingle'
            }
            # ComboBoxes
            elseif ($ctrl -is [System.Windows.Forms.ComboBox]) {
                $ctrl.BackColor = [System.Drawing.ColorTranslator]::FromHtml($theme.textbox_bg)
                $ctrl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($theme.textbox_fg)
                $ctrl.FlatStyle = 'Flat'
            }
            # ListBoxes - Enhanced
            elseif ($ctrl -is [System.Windows.Forms.ListBox]) {
                $ctrl.BackColor = [System.Drawing.ColorTranslator]::FromHtml($theme.textbox_bg)
                $ctrl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($theme.textbox_fg)
                $ctrl.BorderStyle = 'FixedSingle'
            }
            # Labels - Enhanced font for material themes
            elseif ($ctrl -is [System.Windows.Forms.Label]) {
                $ctrl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($theme.foreground)
                
                # Make header labels more prominent
                if ($ctrl.Font.Size -ge 12 -or $ctrl.Font.Bold) {
                    try {
                        if ($theme.PSObject.Properties.Name -contains 'accent') {
                            $ctrl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($theme.accent)
                        } else {
                            $ctrl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($theme.primary)
                        }
                    } catch {}
                }
            }
            # TabControls - Enhanced styling
            elseif ($ctrl -is [System.Windows.Forms.TabControl]) {
                $ctrl.BackColor = [System.Drawing.ColorTranslator]::FromHtml($theme.tab_bg)
                
                foreach ($tab in $ctrl.TabPages) {
                    $tab.BackColor = [System.Drawing.ColorTranslator]::FromHtml($theme.background)
                    $tab.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($theme.foreground)
                    
                    # Add subtle padding to tabs
                    try {
                        $tab.Padding = New-Object System.Windows.Forms.Padding(10, 10, 10, 10)
                    } catch {}
                }
            }
            # GroupBoxes - Enhanced
            elseif ($ctrl -is [System.Windows.Forms.GroupBox]) {
                $ctrl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($theme.foreground)
                
                # Make group titles stand out
                try {
                    if ($theme.PSObject.Properties.Name -contains 'primary') {
                        $ctrl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($theme.primary)
                    }
                } catch {}
            }
            # Panels
            elseif ($ctrl -is [System.Windows.Forms.Panel]) {
                $ctrl.BackColor = [System.Drawing.ColorTranslator]::FromHtml($theme.background)
            }
            # ProgressBars - Enhanced with accent color
            elseif ($ctrl -is [System.Windows.Forms.ProgressBar]) {
                try {
                    if ($theme.PSObject.Properties.Name -contains 'accent') {
                        $ctrl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($theme.accent)
                    } else {
                        $ctrl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($theme.primary)
                    }
                } catch {}
            }
            # StatusStrips
            elseif ($ctrl -is [System.Windows.Forms.StatusStrip]) {
                $ctrl.BackColor = [System.Drawing.ColorTranslator]::FromHtml($theme.tab_bg)
                $ctrl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($theme.foreground)
            }
            
            # Recursively apply to child controls
            if ($ctrl.Controls.Count -gt 0) {
                Apply-ToControl $ctrl
            }
        }
    }
    
    Apply-ToControl $form
}

# Initialize themes
Load-ThemeConfig | Out-Null

# Export functions
Export-ModuleMember -Function Load-ThemeConfig, Save-ThemeConfig, Set-Theme, Get-AvailableThemes, Write-Themed, Apply-GuiTheme
