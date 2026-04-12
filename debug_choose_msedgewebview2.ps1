# ============================================================
# debug_choose_msedgewebview2.ps1
# Helper script for debugging choose_msedgewebview2.ps1
# All write operations are DRY-RUN — registry and env vars are NOT modified
# Run with Administrator privileges (same requirement as the main script)
# ============================================================

$LogFile = Join-Path $PSScriptRoot "debug_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Log {
    param([string]$Msg, [string]$Color = "White")
    Write-Host $Msg -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $Msg -Encoding UTF8
}

function LogSection {
    param([string]$Title)
    $Line = "=" * 60
    Log ""
    Log $Line Cyan
    Log "  $Title" Cyan
    Log $Line Cyan
}

# ── [CHECK 0] Administrator privilege ───────────────────────
LogSection "CHECK 0: Administrator privilege"
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if ($IsAdmin) {
    Log "[PASS] Running as Administrator." Green
} else {
    Log "[WARN] NOT running as Administrator. Some checks may be inaccurate." Yellow
}

# ── [CHECK 1] PowerShell version ────────────────────────────
LogSection "CHECK 1: PowerShell version"
$PSVer = $PSVersionTable.PSVersion
Log "[INFO] PowerShell version: $PSVer" White
if ($PSVer.Major -ge 5) {
    Log "[PASS] Version is 5.0 or above (required)." Green
} else {
    Log "[FAIL] Version below 5.0. Script may not work correctly." Red
}

# ── [CHECK 2] Execution policy ──────────────────────────────
LogSection "CHECK 2: Execution policy"
$PolicyCU = Get-ExecutionPolicy -Scope CurrentUser
$PolicyLM = Get-ExecutionPolicy -Scope LocalMachine
Log "[INFO] CurrentUser  scope: $PolicyCU" White
Log "[INFO] LocalMachine scope: $PolicyLM" White
if ($PolicyCU -in @("Bypass","Unrestricted","RemoteSigned") -or $PolicyLM -in @("Bypass","Unrestricted","RemoteSigned")) {
    Log "[PASS] Execution policy allows script execution." Green
} else {
    Log "[WARN] Execution policy may block the script. See README for fix." Yellow
}

# ── [CHECK 3] Main script file presence ─────────────────────
LogSection "CHECK 3: Main script file presence"
$MainScript = Join-Path $PSScriptRoot "choose_msedgewebview2.ps1"
if (Test-Path $MainScript) {
    Log "[PASS] choose_msedgewebview2.ps1 found at: $MainScript" Green
} else {
    Log "[FAIL] choose_msedgewebview2.ps1 NOT found at: $MainScript" Red
    Log "       Place this debug script in the same folder as the main script." Yellow
}

# ── [CHECK 4] Main script syntax check (AST parse) ──────────
LogSection "CHECK 4: Main script syntax check (Parse)"
if (Test-Path $MainScript) {
    $ParseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($MainScript, [ref]$null, [ref]$ParseErrors)
    if ($ParseErrors.Count -eq 0) {
        Log "[PASS] No syntax errors found." Green
    } else {
        Log "[FAIL] $($ParseErrors.Count) syntax error(s) detected:" Red
        foreach ($e in $ParseErrors) {
            Log "       Line $($e.Extent.StartLineNumber): $($e.Message)" Red
        }
    }
}

# ── [CHECK 5] Registry path accessibility (read-only) ───────
LogSection "CHECK 5: Registry path accessibility (read-only)"
$WebView2Guid = "{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
$PathsToCheck = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Edge\WebView2\BrowserExecutableFolder",
    "HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\Edge\WebView2\BrowserExecutableFolder",
    "HKCU:\SOFTWARE\Policies\Microsoft\Edge\WebView2\BrowserExecutableFolder",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\$WebView2Guid",
    "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\$WebView2Guid"
)
foreach ($p in $PathsToCheck) {
    if (Test-Path $p) {
        Log "[EXIST]  $p" Green
    } else {
        Log "[ABSENT] $p  (will be created by Mode 1 -- this is normal)" DarkGray
    }
}

# ── [CHECK 6] Current env var state ─────────────────────────
LogSection "CHECK 6: Current WEBVIEW2_BROWSER_EXECUTABLE_FOLDER state"
$EnvVarName = "WEBVIEW2_BROWSER_EXECUTABLE_FOLDER"
$MachineVal = [System.Environment]::GetEnvironmentVariable($EnvVarName, "Machine")
$UserVal    = [System.Environment]::GetEnvironmentVariable($EnvVarName, "User")
$ProcVal    = [System.Environment]::GetEnvironmentVariable($EnvVarName, "Process")
Log "[INFO] Machine : $(if ($MachineVal) { $MachineVal } else { '[not set]' })" White
Log "[INFO] User    : $(if ($UserVal)    { $UserVal    } else { '[not set -- correct]' })" White
Log "[INFO] Process : $(if ($ProcVal)    { $ProcVal    } else { '[not set]' })" White
if ($MachineVal -and -not $UserVal) {
    Log "[PASS] Machine-level set, User-level clear. Configuration looks correct." Green
} elseif (-not $MachineVal) {
    Log "[INFO] Machine-level env var not yet set. Run Mode 1 first." DarkGray
}

# ── [CHECK 7] Live execution (interactive, output captured) ──
LogSection "CHECK 7: Live execution of main script (interactive)"
Log "[INFO] Launching choose_msedgewebview2.ps1 — interact normally." White
Log "[INFO] All output will be mirrored to the log file." White
Log "" White

if (Test-Path $MainScript) {
    try {
        & $MainScript 2>&1 | Tee-Object -Append -FilePath $LogFile
        Log "" White
        Log "[INFO] Main script finished. Exit code: $LASTEXITCODE" White
    } catch {
        Log "[ERROR] Exception while running main script: $_" Red
    }
} else {
    Log "[SKIP] Main script not found, skipping live execution." Yellow
}

# ── Summary ──────────────────────────────────────────────────
LogSection "DEBUG SESSION COMPLETE"
Log "[INFO] Full log saved to: $LogFile" Cyan
Log ""
Write-Host "Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
