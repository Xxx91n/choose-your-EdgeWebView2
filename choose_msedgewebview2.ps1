# ============================================================
# choose_msedgewebview2.ps1
# https://github.com/Xxx91n/choose-your-EdgeWebView2
# ============================================================

# ── [0] 强制 UTF-8 编码（兼容所有系统区域设置）──────────────────────
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

# ── [0] 管理员权限检测 ─────────────────────────────────────────────
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

# ── [0] 手动选择语言 ───────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  choose-your-EdgeWebView2" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Select language / 选择语言:"
Write-Host "  [1] English"
Write-Host "  [2] 简体中文"
Write-Host ""

$LangChoice = $null
while ($LangChoice -notin @("1","2")) {
    $LangChoice = (Read-Host "Enter / 输入 (1 or 2)").Trim()
}

$IsChinese = ($LangChoice -eq "2")

if ($IsChinese) {
    $T = @{
        Separator          = "============================================================"
        ChooseMode         = @"
请选择模式：
  [1] 设置 WebView2 路径（写入环境变量 + 注册表）
  [2] 锁定（为已写入的路径添加 ACL，防止被其他程序覆盖）
  [3] 解锁（移除 ACL 锁定）
"@
        InputMode          = "请输入模式编号 (1 / 2 / 3)"
        InvalidMode        = "[错误] 无效的模式，请输入 1、2 或 3。"
        InputPath          = @"
请粘贴 msedgewebview2.exe 所在文件夹的完整路径
（例如：D:\Test\Microsoft.WebView2.FixedVersionRuntime.133.0.3065.92.x64）
路径
"@
        PathOK             = "[OK] 路径有效，已检测到 msedgewebview2.exe"
        PathFail           = "[错误] 该路径下未找到 msedgewebview2.exe，请重新输入。"
        VersionDetect      = "[自动检测] 版本号"
        Step1              = "[1/4] 写入系统级环境变量"
        Step2              = "[2/4] 写入 WebView2 策略注册表"
        Step3              = "[3/4] 写入 Tauri WebView2 已安装注册表记录"
        Step4              = "[4/4] 验证所有写入结果"
        WrittenOK          = "[OK] 已写入"
        LockStep           = "[锁定] 正在为注册表路径添加 ACL 锁..."
        LockDone           = "[完成] 所有注册表 ACL 锁定已完成。"
        UnlockStep         = "[解锁] 正在移除注册表 ACL 锁..."
        UnlockOK           = "[OK] 已解锁"
        UnlockNoChange     = "[无变化] 未找到 Deny 规则"
        UnlockSkip         = "[跳过] 路径不存在"
        UnlockDone         = "[完成] WebView2 策略注册表已解锁。Environment 键从未被修改，系统变量正常。"
        MachineEnv         = "Machine 级环境变量"
        UserEnv            = "User    级环境变量"
        PolicyReg          = "策略注册表"
        TauriReg           = "Tauri 检测注册表"
        Empty              = "[空]"
        EmptyCorrect       = "[空 - 正确]"
        NotWritten         = "[未写入]"
        Done               = "[完成] 请重启或注销重登，以使环境变量在所有进程中生效。"
        EnvOK              = "[OK] 已设置"
        EnvClear           = "[OK] 已清除 User 级（正确）"
        NeedMode1First     = "[提示] 未检测到已写入的路径，请先使用模式 1 设置路径，再执行锁定。"
        PressAnyKey        = "按任意键退出..."
        AfterMode1Prompt   = "设置完成，请选择下一步操作"
        AfterMode1Lock     = "  [2] 立即执行锁定（推荐）"
        AfterMode1Exit     = "  [X] 退出"
        AfterMode1Input    = "请输入选择 (2 / X)"
        AfterMode1Invalid  = "[错误] 无效输入，请输入 2 或 X。"
    }
} else {
    $T = @{
        Separator          = "============================================================"
        ChooseMode         = @"
Select mode:
  [1] Set WebView2 path (write env var + registry)
  [2] Lock (add ACL to already-written paths to prevent overwriting)
  [3] Unlock (remove ACL locks)
"@
        InputMode          = "Enter mode (1 / 2 / 3)"
        InvalidMode        = "[Error] Invalid mode, please enter 1, 2 or 3."
        InputPath          = @"
Paste the full path to the folder containing msedgewebview2.exe
(e.g.: D:\Test\Microsoft.WebView2.FixedVersionRuntime.133.0.3065.92.x64)
Path
"@
        PathOK             = "[OK] Path valid, msedgewebview2.exe found"
        PathFail           = "[Error] msedgewebview2.exe not found at that path, please re-enter."
        VersionDetect      = "[Auto-detect] Version"
        Step1              = "[1/4] Writing system-level environment variable"
        Step2              = "[2/4] Writing WebView2 policy registry"
        Step3              = "[3/4] Writing Tauri WebView2 installed registry entry"
        Step4              = "[4/4] Verifying all written values"
        WrittenOK          = "[OK] Written"
        LockStep           = "[Lock] Adding ACL locks to registry paths..."
        LockDone           = "[Done] All registry ACL locks applied."
        UnlockStep         = "[Unlock] Removing registry ACL locks..."
        UnlockOK           = "[OK] Unlocked"
        UnlockNoChange     = "[No change] No Deny rule found"
        UnlockSkip         = "[Skip] Path does not exist"
        UnlockDone         = "[Done] WebView2 policy registry unlocked. The Environment key was never modified; system variables are intact."
        MachineEnv         = "Machine-level env var"
        UserEnv            = "User-level env var   "
        PolicyReg          = "Policy registry"
        TauriReg           = "Tauri detection reg"
        Empty              = "[empty]"
        EmptyCorrect       = "[empty - correct]"
        NotWritten         = "[not written]"
        Done               = "[Done] Please restart or re-login for env var changes to take effect in all processes."
        EnvOK              = "[OK] Set"
        EnvClear           = "[OK] User-level cleared (correct)"
        NeedMode1First     = "[Notice] No existing path detected. Please use Mode 1 to set the path first before locking."
        PressAnyKey        = "Press any key to exit..."
        AfterMode1Prompt   = "Setup complete. Choose next action"
        AfterMode1Lock     = "  [2] Apply ACL lock now (recommended)"
        AfterMode1Exit     = "  [X] Exit"
        AfterMode1Input    = "Enter choice (2 / X)"
        AfterMode1Invalid  = "[Error] Invalid input, please enter 2 or X."
    }
}

# ── 常量（所有 Windows 电脑相同，无需动态获取）────────────────────
$EnvVarName   = "WEBVIEW2_BROWSER_EXECUTABLE_FOLDER"
$WebView2Guid = "{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"

$PolicyPath64 = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\WebView2\BrowserExecutableFolder"
$PolicyPath32 = "HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\Edge\WebView2\BrowserExecutableFolder"
$PolicyPathCU = "HKCU:\SOFTWARE\Policies\Microsoft\Edge\WebView2\BrowserExecutableFolder"
$TauriPaths   = @(
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\$WebView2Guid",
    "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\$WebView2Guid"
)

# ACL 账户列表（策略注册表路径用）
$PolicyACLAccounts = @("BUILTIN\Users", "NT AUTHORITY\NETWORK SERVICE", "NT AUTHORITY\LOCAL SERVICE")
# ACL 账户列表（Tauri 注册表路径用）
$TauriACLAccounts  = @("NT AUTHORITY\NETWORK SERVICE", "NT AUTHORITY\LOCAL SERVICE")

# ── 内部函数：通过底层 .NET API 添加 Deny ACL（绕开 Set-Acl 的权限限制）─
function Add-DenyACL {
    param([string]$RegPath, [string[]]$Accounts)
    if (-not (Test-Path $RegPath)) { return }

    # 将 PowerShell 路径格式转换为 .NET RegistryKey 格式
    $hive    = $RegPath -replace '^(HKLM|HKCU):.*', '$1'
    $subKey  = $RegPath -replace '^HKL[MC]:\\', '' -replace '^HKCU:\\', ''
    $rootKey = if ($hive -eq 'HKLM') {
        [Microsoft.Win32.Registry]::LocalMachine
    } else {
        [Microsoft.Win32.Registry]::CurrentUser
    }

    try {
        $key = $rootKey.OpenSubKey(
            $subKey,
            [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
            [System.Security.AccessControl.RegistryRights]::ChangePermissions
        )
        if ($null -eq $key) { return }
        $acl = $key.GetAccessControl()
        foreach ($acct in $Accounts) {
            $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
                $acct, "SetValue,Delete,CreateSubKey", "None", "None", "Deny"
            )
            $acl.AddAccessRule($rule)
        }
        $key.SetAccessControl($acl)
        $key.Close()
    } catch {
        Write-Host "  [WARN] ACL failed on ${RegPath}: $_" -ForegroundColor DarkYellow
    }
}

# ── 内部函数：通过底层 .NET API 移除 Deny ACL ─────────────────────
function Remove-DenyACL {
    param([string]$RegPath, [string[]]$Accounts)
    if (-not (Test-Path $RegPath)) {
        Write-Host "  $($T.UnlockSkip): $RegPath" -ForegroundColor DarkGray
        return
    }

    $hive    = $RegPath -replace '^(HKLM|HKCU):.*', '$1'
    $subKey  = $RegPath -replace '^HKL[MC]:\\', '' -replace '^HKCU:\\', ''
    $rootKey = if ($hive -eq 'HKLM') {
        [Microsoft.Win32.Registry]::LocalMachine
    } else {
        [Microsoft.Win32.Registry]::CurrentUser
    }

    try {
        $key = $rootKey.OpenSubKey(
            $subKey,
            [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
            [System.Security.AccessControl.RegistryRights]::ChangePermissions
        )
        if ($null -eq $key) {
            Write-Host "  $($T.UnlockSkip): $RegPath" -ForegroundColor DarkGray
            return
        }
        $acl     = $key.GetAccessControl()
        $changed = $false
        foreach ($acct in $Accounts) {
            $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
                $acct, "SetValue,Delete,CreateSubKey", "None", "None", "Deny"
            )
            if ($acl.RemoveAccessRule($rule)) { $changed = $true }
        }
        if ($changed) {
            $key.SetAccessControl($acl)
            Write-Host "  $($T.UnlockOK): $RegPath" -ForegroundColor Green
        } else {
            Write-Host "  $($T.UnlockNoChange): $RegPath" -ForegroundColor DarkYellow
        }
        $key.Close()
    } catch {
        Write-Host "  [WARN] ACL remove failed on ${RegPath}: $_" -ForegroundColor DarkYellow
    }
}

# ── 内部函数：执行锁定（模式1完成后与模式2共用）─────────────────────
function Invoke-LockMode {
    Write-Host ""
    Write-Host $T.LockStep -ForegroundColor Cyan

    foreach ($p in @($PolicyPath64, $PolicyPath32, $PolicyPathCU)) {
        if (Test-Path $p) {
            Add-DenyACL -RegPath $p -Accounts $PolicyACLAccounts
            Write-Host "  [OK] $p" -ForegroundColor Green
        }
    }
    foreach ($p in $TauriPaths) {
        if (Test-Path $p) {
            Add-DenyACL -RegPath $p -Accounts $TauriACLAccounts
            Write-Host "  [OK] $p" -ForegroundColor Green
        }
    }

    Write-Host ""
    Write-Host $T.LockDone -ForegroundColor Green
}

# ════════════════════════════════════════════════════════════
# 主菜单
# ════════════════════════════════════════════════════════════
Write-Host ""
Write-Host $T.ChooseMode

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

    foreach ($p in @($PolicyPath64, $PolicyPath32, $PolicyPathCU)) {
        Remove-DenyACL -RegPath $p -Accounts $PolicyACLAccounts
    }
    foreach ($p in $TauriPaths) {
        Remove-DenyACL -RegPath $p -Accounts $TauriACLAccounts
    }

    Write-Host ""
    Write-Host $T.UnlockDone -ForegroundColor Green
    Write-Host ""
    Write-Host $T.PressAnyKey -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

# ════════════════════════════════════════════════════════════
# 模式 2：仅锁定
# ════════════════════════════════════════════════════════════
if ($Mode -eq "2") {
    $ExistingPath = [System.Environment]::GetEnvironmentVariable($EnvVarName, "Machine")
    if (-not $ExistingPath) {
        Write-Host ""
        Write-Host $T.NeedMode1First -ForegroundColor Yellow
        Write-Host ""
        Write-Host $T.PressAnyKey -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }

    Invoke-LockMode

    Write-Host ""
    Write-Host $T.PressAnyKey -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

# ════════════════════════════════════════════════════════════
# 模式 1：设置路径 + 写入环境变量和注册表
# ════════════════════════════════════════════════════════════

# ── 输入路径，循环验证 ─────────────────────────────────────────────
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

# ── 自动读取版本号 ─────────────────────────────────────────────────
$VerInfo         = (Get-Item (Join-Path $WebView2Path "msedgewebview2.exe")).VersionInfo
$WebView2Version = if ($VerInfo.ProductVersion) { $VerInfo.ProductVersion } else { $VerInfo.FileVersion }
Write-Host "$($T.VersionDetect): $WebView2Version" -ForegroundColor Green
Write-Host ""

# ── [1/4] 写入系统级环境变量 ──────────────────────────────────────
Write-Host "========== $($T.Step1) ==========" -ForegroundColor Cyan

[System.Environment]::SetEnvironmentVariable($EnvVarName, $WebView2Path, "Machine")
[System.Environment]::SetEnvironmentVariable($EnvVarName, $null,         "User")
[System.Environment]::SetEnvironmentVariable($EnvVarName, $WebView2Path, "Process")

Write-Host "$($T.EnvOK)  [Machine] $EnvVarName = $WebView2Path" -ForegroundColor Green
Write-Host "$($T.EnvClear)" -ForegroundColor Green

# ── [2/4] 写入策略注册表 ──────────────────────────────────────────
Write-Host ""
Write-Host "========== $($T.Step2) ==========" -ForegroundColor Cyan

foreach ($p in @($PolicyPath64, $PolicyPath32, $PolicyPathCU)) {
    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
    Set-ItemProperty -Path $p -Name "*" -Value $WebView2Path -Type String
    Write-Host "$($T.WrittenOK): $p" -ForegroundColor Green
}

# ── [3/4] 写入 Tauri 注册表 ──────────────────────────────────────
Write-Host ""
Write-Host "========== $($T.Step3) ==========" -ForegroundColor Cyan

foreach ($p in $TauriPaths) {
    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
    Set-ItemProperty -Path $p -Name "pv"   -Value $WebView2Version -Type String
    Set-ItemProperty -Path $p -Name "name" -Value "Microsoft Edge WebView2 Runtime" -Type String
    Write-Host "$($T.WrittenOK): $p  (pv=$WebView2Version)" -ForegroundColor Green
}

# ── [4/4] 验证 ───────────────────────────────────────────────────
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

# ── 模式1完成后：询问是否立即锁定 ────────────────────────────────
Write-Host ""
Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host $T.AfterMode1Prompt -ForegroundColor Cyan
Write-Host $T.AfterMode1Lock
Write-Host $T.AfterMode1Exit
Write-Host ""

$PostChoice = $null
while ($PostChoice -notin @("2","x","X")) {
    $PostChoice = (Read-Host $T.AfterMode1Input).Trim()
    if ($PostChoice -notin @("2","x","X")) {
        Write-Host $T.AfterMode1Invalid -ForegroundColor Red
    }
}

if ($PostChoice -eq "2") {
    Invoke-LockMode
}

Write-Host ""
Write-Host $T.PressAnyKey -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
