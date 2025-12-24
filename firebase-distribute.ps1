# Firebase App Distribution Script
# Gemini CLI Style Design

$ErrorActionPreference = "Stop"

# Set working directory to script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

function Get-GitBranch {
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($branch) { return $branch.Trim() }
    } catch {}
    return "unknown"
}

function Get-GitAuthor {
    try {
        $author = git config user.name 2>$null
        if ($author) { return $author.Trim() }
    } catch {}
    return "Unknown Author"
}

function Get-VersionName {
    try {
        $content = Get-Content "app/build.gradle.kts" -Raw
        if ($content -match 'versionName\s*=\s*"([^"]+)"') {
            return $matches[1]
        }
    } catch {}
    return "unknown"
}

function Get-VersionCode {
    try {
        $content = Get-Content "app/build.gradle.kts" -Raw
        if ($content -match 'versionCode\s*=\s*(\d+)') {
            return $matches[1]
        }
    } catch {}
    return "unknown"
}

function Show-Banner {
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2726) -ForegroundColor Magenta -NoNewline
    Write-Host " " -NoNewline
    Write-Host "Firebase" -ForegroundColor Blue -NoNewline
    Write-Host " App " -ForegroundColor Cyan -NoNewline
    Write-Host "Distribution" -ForegroundColor Magenta
    Write-Host ""
}

function Show-SingleSelectMenu {
    param(
        [string]$Title,
        [string[]]$Options,
        [string]$PrevInfo = ""
    )
    
    $selectedIndex = 0
    
    while ($true) {
        Clear-Host
        Show-Banner
        
        if ($PrevInfo) {
            Write-Host $PrevInfo
            Write-Host ""
        }
        
        Write-Host "  $Title" -ForegroundColor White
        Write-Host "  Use " -ForegroundColor DarkGray -NoNewline
        Write-Host "arrows" -ForegroundColor Cyan -NoNewline
        Write-Host " to navigate, " -ForegroundColor DarkGray -NoNewline
        Write-Host "Enter" -ForegroundColor Cyan -NoNewline
        Write-Host " to select" -ForegroundColor DarkGray
        Write-Host ""
        
        for ($i = 0; $i -lt $Options.Count; $i++) {
            if ($i -eq $selectedIndex) {
                Write-Host "    " -NoNewline
                Write-Host ([char]0x25CF) -ForegroundColor Magenta -NoNewline
                Write-Host " $($Options[$i])" -ForegroundColor White
            } else {
                Write-Host "    " -NoNewline
                Write-Host ([char]0x25CB) -ForegroundColor DarkGray -NoNewline
                Write-Host " $($Options[$i])" -ForegroundColor DarkGray
            }
        }
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up Arrow
                $selectedIndex--
                if ($selectedIndex -lt 0) { $selectedIndex = $Options.Count - 1 }
            }
            40 { # Down Arrow
                $selectedIndex++
                if ($selectedIndex -ge $Options.Count) { $selectedIndex = 0 }
            }
            13 { # Enter
                return $Options[$selectedIndex]
            }
        }
    }
}

function Show-MultiSelectMenu {
    param(
        [string]$Title,
        [string[]]$Options,
        [string]$PrevInfo = ""
    )
    
    $selectedIndex = 0
    $selected = @{}
    foreach ($opt in $Options) { $selected[$opt] = $false }
    $selected[$Options[0]] = $true
    
    while ($true) {
        Clear-Host
        Show-Banner
        
        if ($PrevInfo) {
            Write-Host $PrevInfo
            Write-Host ""
        }
        
        Write-Host "  $Title" -ForegroundColor White
        Write-Host "  Use " -ForegroundColor DarkGray -NoNewline
        Write-Host "arrows" -ForegroundColor Cyan -NoNewline
        Write-Host " to navigate, " -ForegroundColor DarkGray -NoNewline
        Write-Host "Space" -ForegroundColor Cyan -NoNewline
        Write-Host " to toggle, " -ForegroundColor DarkGray -NoNewline
        Write-Host "Enter" -ForegroundColor Cyan -NoNewline
        Write-Host " to confirm" -ForegroundColor DarkGray
        Write-Host ""
        
        for ($i = 0; $i -lt $Options.Count; $i++) {
            $isSelected = $selected[$Options[$i]]
            if ($isSelected) {
                $checkbox = [char]0x25C6
                $checkColor = "Magenta"
            } else {
                $checkbox = [char]0x25C7
                $checkColor = "DarkGray"
            }
            
            if ($i -eq $selectedIndex) {
                Write-Host "    " -NoNewline
                Write-Host $checkbox -ForegroundColor $checkColor -NoNewline
                Write-Host " $($Options[$i])" -ForegroundColor White
            } else {
                Write-Host "    " -NoNewline
                Write-Host $checkbox -ForegroundColor $checkColor -NoNewline
                Write-Host " $($Options[$i])" -ForegroundColor DarkGray
            }
        }
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up Arrow
                $selectedIndex--
                if ($selectedIndex -lt 0) { $selectedIndex = $Options.Count - 1 }
            }
            40 { # Down Arrow
                $selectedIndex++
                if ($selectedIndex -ge $Options.Count) { $selectedIndex = 0 }
            }
            32 { # Space
                $selected[$Options[$selectedIndex]] = -not $selected[$Options[$selectedIndex]]
            }
            13 { # Enter
                $result = $Options | Where-Object { $selected[$_] }
                if (-not $result) { $result = @($Options[0]) }
                return ($result -join ", ")
            }
        }
    }
}

function Show-ConfirmMenu {
    param([string]$Summary)
    
    $selectedIndex = 0
    
    while ($true) {
        Clear-Host
        Show-Banner
        
        Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
        Write-Host "  Build Summary" -ForegroundColor White
        Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host $Summary
        Write-Host ""
        Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Proceed with build and upload?" -ForegroundColor White
        Write-Host ""
        
        $filled = [char]0x25CF
        $empty = [char]0x25CB
        
        if ($selectedIndex -eq 0) {
            Write-Host "    " -NoNewline
            Write-Host $filled -ForegroundColor Magenta -NoNewline
            Write-Host " Yes" -ForegroundColor White -NoNewline
            Write-Host "     " -NoNewline
            Write-Host $empty -ForegroundColor DarkGray -NoNewline
            Write-Host " No" -ForegroundColor DarkGray
        } else {
            Write-Host "    " -NoNewline
            Write-Host $empty -ForegroundColor DarkGray -NoNewline
            Write-Host " Yes" -ForegroundColor DarkGray -NoNewline
            Write-Host "     " -NoNewline
            Write-Host $filled -ForegroundColor Magenta -NoNewline
            Write-Host " No" -ForegroundColor White
        }
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            37 { $selectedIndex = 0 } # Left Arrow
            39 { $selectedIndex = 1 } # Right Arrow
            38 { $selectedIndex = 1 - $selectedIndex } # Up Arrow
            40 { $selectedIndex = 1 - $selectedIndex } # Down Arrow
            13 { return $selectedIndex -eq 0 } # Enter
        }
    }
}

function Show-TextInput {
    param(
        [string]$Prompt,
        [string]$DefaultValue,
        [string]$PrevInfo = ""
    )
    
    Clear-Host
    Show-Banner
    
    if ($PrevInfo) {
        Write-Host $PrevInfo
        Write-Host ""
    }
    
    Write-Host "  $Prompt" -ForegroundColor White
    Write-Host "  Press " -ForegroundColor DarkGray -NoNewline
    Write-Host "Enter" -ForegroundColor Cyan -NoNewline
    Write-Host " for default" -ForegroundColor DarkGray
    Write-Host ""
    
    $arrow = [char]0x203A
    Write-Host "    " -NoNewline
    Write-Host $arrow -ForegroundColor Magenta -NoNewline
    Write-Host " " -NoNewline
    
    $userInput = Read-Host
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        return $DefaultValue
    }
    return $userInput
}

# =============================================
# MAIN SCRIPT
# =============================================

# Step 1: Select build type
$buildType = Show-SingleSelectMenu -Title "Select build type" -Options @("Debug", "Release")
$info1 = "  $([char]0x2713) Build type: $buildType"

# Step 2: Enter description
$description = Show-TextInput -Prompt "Enter release description" -DefaultValue "No description provided" -PrevInfo $info1

$info2 = $info1 + "`n  $([char]0x2713) Description: $description"

# Step 3: Select groups
$groups = Show-MultiSelectMenu -Title "Select tester group(s)" -Options @("qa", "qa-team", "devs") -PrevInfo $info2

# Get Git and version information
$gitBranch = Get-GitBranch
$gitAuthor = Get-GitAuthor
$versionName = Get-VersionName
$versionCode = Get-VersionCode

# Create summary
$summaryText = @"
    Build Type   $buildType
    Description  $description
    Groups       $groups
    Branch       $gitBranch
    Author       $gitAuthor
    Version      $versionName ($versionCode)
"@

# Create release notes
$releaseNotesDir = "app/build"
$releaseNotesFile = "$releaseNotesDir/release-notes.txt"

if (-not (Test-Path $releaseNotesDir)) {
    New-Item -ItemType Directory -Path $releaseNotesDir -Force | Out-Null
}

$releaseNotes = @"
BuildType: $buildType
Version: $versionName
Branch: $gitBranch
Description: $description
Author: $gitAuthor
Groups: $groups
"@

Set-Content -Path $releaseNotesFile -Value $releaseNotes

# Ask for confirmation
$confirmed = Show-ConfirmMenu -Summary $summaryText

if (-not $confirmed) {
    Clear-Host
    Show-Banner
    Write-Host "  Build cancelled." -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

# Build and upload
Clear-Host
Show-Banner
Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
Write-Host "  Building & Uploading" -ForegroundColor White
Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  $([char]0x2713) Release notes saved" -ForegroundColor Green
Write-Host ""

$arrow = [char]0x203A
Write-Host "  " -NoNewline
Write-Host $arrow -ForegroundColor Magenta -NoNewline
Write-Host " Running " -ForegroundColor DarkGray -NoNewline
Write-Host "./gradlew assemble$buildType" -ForegroundColor Cyan
Write-Host ""

& ./gradlew "assemble$buildType"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "  $([char]0x2713) Build successful" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "  X Build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "  " -NoNewline
Write-Host $arrow -ForegroundColor Magenta -NoNewline
Write-Host " Running " -ForegroundColor DarkGray -NoNewline
Write-Host "./gradlew appDistributionUpload$buildType" -ForegroundColor Cyan
Write-Host ""

& ./gradlew "appDistributionUpload$buildType"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "  ----------------------------------------" -ForegroundColor Magenta
    Write-Host "  " -NoNewline
    Write-Host ([char]0x2726) -ForegroundColor Magenta -NoNewline
    Write-Host " Upload complete!" -ForegroundColor White
    Write-Host "  ----------------------------------------" -ForegroundColor Magenta
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "  X Upload failed" -ForegroundColor Red
    exit 1
}
