# ============================================================
# choose_msedgewebview2.ps1
# https://github.com/Xxx91n/choose-your-EdgeWebView2
# ============================================================

# ── [0] 管理员权限检测 ────────────────────────────────────────
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $IsAdmin) {
    Write-Host ""
    Write-Host "[错误] 请以管理员权限运行此脚本！右键 -> 以管理员身份运行。" -ForegroundColor Red
    Write-Host "[Error] Please run this script as Administrator! Right-click -> Run as administrator." -ForegroundColor Red
    Write-Host ""
    Write-Host "按任意键退出 / Press any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# ── [0] 语言检测（UI 语言，zh-* = 中文，其余默认英文）─────────
$UILang    = (Get-UICulture).Name   # 例如 zh-CN / zh-TW / zh-HK / en-US / ja-JP ...
$IsChinese = $UILang -match '^zh'

if ($IsChinese) {
    $T = @{
        Welcome        = "欢迎使用 choose-your-EdgeWebView2"
        Separator      = "============================================================"
        ChooseMode     = @"
请选择模式：
  [1] 设置 WebView2 路径（写入环境变量 + 注册表）
  [2] 锁定（为已写入的路径加 ACL，防止被其他程序覆盖）
  [3] 解锁（移除 ACL 锁定）
"@
        InputMode      = "请输入模式编号 (1 / 2 / 3): "
        InvalidMode    = "[错误] 无效的模式，请输入 1、2 或 3。"
        InputPath      = "请粘贴 msedgewebview2.exe 所在文件夹的完整路径`n（例如：D:\Test\Microsoft.WebView2.FixedVersionRuntime.133.0.3065.92.x64）`n路径: "
        PathOK         = "[OK] 路径有效，已检测到 msedgewebview2.exe"
        PathFail       = "[错误] 该路径下未找到 msedgewebview2.exe，请重新输入。"
        VersionDetect  = "[自动检测] 版本号"
        Step1          = "[1/4] 写入系统级环境变量"
        Step2          = "[2/4] 写入 WebView2 策略注册表"
        Step3          = "[3/4] 写入 Tauri WebView2 已安装注册表记录"
        Step4          = "[4/4] 验证所有写入结果"
        WrittenOK      = "[OK] 已写入"
        LockStep       = "[锁定] 正在为注册表路径添加 ACL 锁..."
        LockDone       = "[完成] 所有注册表 ACL 锁定已完成。"
        UnlockStep     = "[解锁] 正在移除注册表 ACL 锁..."
        UnlockDone     = "[完成] 所有注册表 ACL 已解锁。"
        UnlockNotFound = "[提示] 路径不存在，跳过"
        MachineEnv     = "Machine 级环境变量"
        UserEnv        = "User    级环境变量"
        PolicyReg      = "策略注册表"
        TauriReg       = "Tauri 检测注册表"
        Empty          = "[空]"
        EmptyCorrect   = "[空 - 正确]"
        NotWritten     = "[未写入]"
        Done           = "[完成] 请重启或注销重登，以使环境变量在所有进程中生效。"
        EnvOK          = "[OK] 已设置"
        EnvClear       = "[OK] 已清除 User 级（正确）"
        NeedMode1First = "[提示] 未检测到已写入的路径，请先使用模式 1 设置路径，再执行锁定。"
    }
} else {
    $T = @{
        Welcome        = "Welcome to choose-your-EdgeWebView2"
        Separator      = "============================================================"
        ChooseMode     = @"
Select mode:
  [1] Set WebView2 path (write env var + registry)
  [2] Lock (add ACL to already-written paths to prevent overwriting)
  [3] Unlock (remove ACL locks)
"@
        InputMode      = "Enter mode (1 / 2 / 3): "
        InvalidMode    = "[Error] Invalid mode, please enter 1, 2 or 3."
        InputPath      = "Paste the full path to the folder containing msedgewebview2.exe`n(e.g.: D:\Test\Microsoft.WebView2.FixedVersionRuntime.133.0.3065.92.x64)`nPath: "
        PathOK         = "[OK] Path valid, msedgewebview2.exe found"
        PathFail       = "[Error] msedgewebview2.exe not found at that path, please re-enter."
        VersionDetect  = "[Auto-detect] Version"
        Step1          = "[1/4] Writing system-level environment variable"
        Step2          = "[2/4] Writing WebView2 policy registry"
        Step3          = "[3/4] Writing Tauri WebView2 installed registry entry"
        Step4          = "[4/4] Verifying all written values"
        WrittenOK      = "[OK] Written"
        LockStep       = "[Lock] Adding ACL locks to registry paths..."
        LockDone       = "[Done] All registry ACL locks applied."
        UnlockStep     = "[Unlock] Removing registry ACL locks..."
        UnlockDone     = "[Done] All registry ACLs removed."
        UnlockNotFound = "[Skip] Path does not exist, skipping"
        MachineEnv     = "Machine-level env var"
        UserEnv        = "User-level env var   "
        PolicyReg      = "Policy registry"
        TauriReg       = "Tauri detection reg"
        Empty          = "[empty]"
        EmptyCorrect   = "[empty - correct]"
        NotWritten     = "[not written]"
        Done           = "[Done] Please restart or re-login for env var changes to take effect in all processes."
        EnvOK          = "[OK] Set"
        EnvClear       = "[OK] User-level cleared (correct)"
        NeedMode1First = "[Notice] No existing path detected. Please use Mode 1 to set the path first before locking."
    }
}

# ── 常量（所有 Windows 电脑相同，无需动态获取）────────────────
$EnvVarName   = "WEBVIEW2_BROWSER_EXECUTABLE_FOLDER"
$WebView2Guid = "{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"

$PolicyPath64 = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\WebView2\BrowserExecutableFolder"
$PolicyPath32 = "HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\Edge\WebView2\BrowserExecutableFolder"
$PolicyPathCU = "HKCU:\SOFTWARE\Policies\Microsoft\Edge\WebView2\BrowserExecutableFolder"
$TauriPaths   = @(
    "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\$WebView2Guid",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\$WebView2Guid"
)
$AllRegPaths  = @($PolicyPath64, $PolicyPath32, $PolicyPathCU) + $TauriPaths

# ── 内部函数：为注册表路径添加 Deny ACL ──────────────────────
function Add-DenyACL {
    param([string]$RegPath, [string[]]$Accounts)
    if (-not (Test-Path $RegPath)) { return }
    $acl = Get-Acl $RegPath
    foreach ($acct in $Accounts) {
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
            $acct, "SetValue,Delete,CreateSubKey", "None", "None", "Deny"
        )
        $acl.AddAccessRule($rule)
    }
    Set-Acl -Path $RegPath -AclObject $acl
}

# ── 内部函数：移除注册表路径的所有 Deny ACL ──────────────────
function Remove-DenyACL {
    param([string]$RegPath)
    if (-not (Test-Path $RegPath)) {
        Write-Host "  $($T.UnlockNotFound): $RegPath" -ForegroundColor DarkGray
        return
    }
    $acl = Get-Acl $RegPath
    $denyRules = $acl.Access | Where-Object { $_.AccessControlType -eq "Deny" }
    foreach ($rule in $denyRules) {
        $acl.RemoveAccessRule($rule) | Out-Null
    }
    Set-Acl -Path $RegPath -AclObject $acl
    Write-Host "  [OK] $RegPath" -ForegroundColor Green
}

# ════════════════════════════════════════════════════════════
# 启动界面
# ════════════════════════════════════════════════════════════
Write-Host ""
Write-Host $T.Separator -ForegroundColor Cyan
Write-Host "  $($T.Welcome)" -ForegroundColor Cyan
Write-Host $T.Separator -ForegroundColor Cyan
Write-Host ""
Write-Host $T.ChooseMode

# ── 读取模式（循环直到有效输入）─────────────────────────────
$Mode = $null
while ($Mode -notin @("1","2","3")) {
    $Mode = (Read-Host $T.InputMode).Trim()
    if ($Mode -notin @("1","2","3")) {
        Write-Host $T.InvalidMode -ForegroundColor Red
    }
}

# ════════════════════════════════════════════════════════════
# 模式 3：解锁
# ════════════════════════════════════════════════════════════
if ($Mode -eq "3") {
    Write-Host ""
    Write-Host $T.UnlockStep -ForegroundColor Cyan
    foreach ($p in $AllRegPaths) {
        Remove-DenyACL -RegPath $p
    }
    Write-Host ""
    Write-Host $T.UnlockDone -ForegroundColor Green
    Write-Host ""
    exit 0
}

# ════════════════════════════════════════════════════════════
# 模式 2：仅锁定（要求路径已通过模式 1 写入）
# ════════════════════════════════════════════════════════════
if ($Mode -eq "2") {
    $ExistingPath = [System.Environment]::GetEnvironmentVariable($EnvVarName, "Machine")
    if (-not $ExistingPath) {
        Write-Host ""
        Write-Host $T.NeedMode1First -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }

    Write-Host ""
    Write-Host $T.LockStep -ForegroundColor Cyan

    foreach ($p in @($PolicyPath64, $PolicyPath32, $PolicyPathCU)) {
        if (Test-Path $p) {
            Add-DenyACL -RegPath $p -Accounts @("BUILTIN\Users","NT AUTHORITY\NETWORK SERVICE","NT AUTHORITY\LOCAL SERVICE")
            Write-Host "  [OK] $p" -ForegroundColor Green
        }
    }
    foreach ($p in $TauriPaths) {
        if (Test-Path $p) {
            Add-DenyACL -RegPath $p -Accounts @("NT AUTHORITY\NETWORK SERVICE","NT AUTHORITY\LOCAL SERVICE")
            Write-Host "  [OK] $p" -ForegroundColor Green
        }
    }

    Write-Host ""
    Write-Host $T.LockDone -ForegroundColor Green
    Write-Host ""
    exit 0
}

# ════════════════════════════════════════════════════════════
# 模式 1：设置路径 + 写入环境变量和注册表
# ════════════════════════════════════════════════════════════

# ── 输入路径，循环验证直到找到 exe ───────────────────────────
$WebView2Path = $null
while ($true) {
    $Raw     = (Read-Host $T.InputPath).Trim().Trim('"').TrimEnd('\')
    $ExeFile = Join-Path $Raw "msedgewebview2.exe"
    if (Test-Path $ExeFile) {
        $WebView2Path = $Raw
        Write-Host $T.PathOK -ForegroundColor Green
        break
    } else {
        Write-Host $T.PathFail -ForegroundColor Red
    }
}

# ── 自动读取版本号 ────────────────────────────────────────────
$VerInfo         = (Get-Item (Join-Path $WebView2Path "msedgewebview2.exe")).VersionInfo
$WebView2Version = if ($VerInfo.ProductVersion) { $VerInfo.ProductVersion } else { $VerInfo.FileVersion }
Write-Host "$($T.VersionDetect): $WebView2Version" -ForegroundColor Green
Write-Host ""

# ── [1/4] 写入系统级环境变量 ─────────────────────────────────
Write-Host "========== $($T.Step1) ==========" -ForegroundColor Cyan

[System.Environment]::SetEnvironmentVariable($EnvVarName, $WebView2Path, "Machine")
[System.Environment]::SetEnvironmentVariable($EnvVarName, $null,         "User")
[System.Environment]::SetEnvironmentVariable($EnvVarName, $WebView2Path, "Process")

Write-Host "$($T.EnvOK)  [Machine] $EnvVarName = $WebView2Path" -ForegroundColor Green
Write-Host "$($T.EnvClear)" -ForegroundColor Green

# ── [2/4] 写入策略注册表 ─────────────────────────────────────
Write-Host ""
Write-Host "========== $($T.Step2) ==========" -ForegroundColor Cyan

foreach ($p in @($PolicyPath64, $PolicyPath32, $PolicyPathCU)) {
    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
    Set-ItemProperty -Path $p -Name "*" -Value $WebView2Path -Type String
    Write-Host "$($T.WrittenOK): $p" -ForegroundColor Green
}

# ── [3/4] 写入 Tauri 注册表 ──────────────────────────────────
Write-Host ""
Write-Host "========== $($T.Step3) ==========" -ForegroundColor Cyan

foreach ($p in $TauriPaths) {
    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
    Set-ItemProperty -Path $p -Name "pv"   -Value $WebView2Version -Type String
    Set-ItemProperty -Path $p -Name "name" -Value "Microsoft Edge WebView2 Runtime" -Type String
    Write-Host "$($T.WrittenOK): $p  (pv=$WebView2Version)" -ForegroundColor Green
}

# ── [4/4] 验证 ───────────────────────────────────────────────
Write-Host ""
Write-Host "========== $($T.Step4) ==========" -ForegroundColor Cyan

$MachineVal = [System.Environment]::GetEnvironmentVariable($EnvVarName, "Machine")
$UserVal    = [System.Environment]::GetEnvironmentVariable($EnvVarName, "User")
Write-Host "$($T.MachineEnv) : $(if ($MachineVal) { $MachineVal } else { $T.Empty })"
Write-Host "$($T.UserEnv)    : $(if ($UserVal)    { $UserVal    } else { $T.EmptyCorrect })"

foreach ($p in @($PolicyPath64, $PolicyPath32, $PolicyPathCU)) {
    $val = (Get-ItemProperty -Path $p -Name "*" -ErrorAction SilentlyContinue)."*"
    Write-Host "$($T.PolicyReg)  $($p.Split('\')[-3..-1] -join '\') = $(if ($val) { $val } else { $T.NotWritten })"
}

foreach ($p in $TauriPaths) {
    $pv = (Get-ItemProperty -Path $p -Name "pv" -ErrorAction SilentlyContinue).pv
    Write-Host "$($T.TauriReg)  $($p.Split('\')[-3..-1] -join '\')  pv = $(if ($pv) { $pv } else { $T.NotWritten })"
}

Write-Host ""
Write-Host $T.Done -ForegroundColor Yellow
Write-Host ""
