# ── [1/4] 写入系统级环境变量 ────────────────────────────────────────
Write-Host "========== [1/4] 写入系统级环境变量 ==========" -ForegroundColor Cyan

[System.Environment]::SetEnvironmentVariable($EnvVarName, $WebView2Path, "Machine")
[System.Environment]::SetEnvironmentVariable($EnvVarName, $null,         "User")
[System.Environment]::SetEnvironmentVariable($EnvVarName, $WebView2Path, "Process")

Write-Host "[OK] $EnvVarName = $WebView2Path" -ForegroundColor Green


# ── [2/4] 写入策略注册表并锁定（仅针对 WebView2 策略路径）───────────
Write-Host "`n========== [2/4] 写入并锁定 WebView2 策略注册表 ==========" -ForegroundColor Cyan

foreach ($path in @($PolicyPath64, $PolicyPath32, $PolicyPathCU)) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    Set-ItemProperty -Path $path -Name "*" -Value $WebView2Path -Type String

    # 只对这个策略键本身加 Deny-Write，不影响 Environment 键
    $acl = Get-Acl $path
    foreach ($account in @("BUILTIN\Users", "NT AUTHORITY\NETWORK SERVICE", "NT AUTHORITY\LOCAL SERVICE")) {
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
            $account, "SetValue,Delete,CreateSubKey", "None", "None", "Deny"
        )
        $acl.AddAccessRule($rule)
    }
    Set-Acl -Path $path -AclObject $acl
    Write-Host "[OK] 已写入并锁定: $path" -ForegroundColor Green
}


# ── [3/4] 伪造 Tauri WebView2 已安装注册表记录 ──────────────────────
Write-Host "`n========== [3/4] 伪造 Tauri WebView2 已安装记录 ==========" -ForegroundColor Cyan

foreach ($path in $TauriPaths) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    Set-ItemProperty -Path $path -Name "pv"   -Value $WebView2Version -Type String
    Set-ItemProperty -Path $path -Name "name" -Value "Microsoft Edge WebView2 Runtime" -Type String

    # 同样只锁定这个检测键，防止被 EdgeUpdate 服务覆盖
    $acl = Get-Acl $path
    foreach ($account in @("NT AUTHORITY\NETWORK SERVICE", "NT AUTHORITY\LOCAL SERVICE")) {
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
            $account, "SetValue,Delete,CreateSubKey", "None", "None", "Deny"
        )
        $acl.AddAccessRule($rule)
    }
    Set-Acl -Path $path -AclObject $acl
    Write-Host "[OK] 已写入并锁定: $path (pv=$WebView2Version)" -ForegroundColor Green
}


# ── [4/4] 验证 ───────────────────────────────────────────────────────
Write-Host "`n========== [4/4] 验证所有写入结果 ==========" -ForegroundColor Cyan

$MachineVal = [System.Environment]::GetEnvironmentVariable($EnvVarName, "Machine")
$UserVal    = [System.Environment]::GetEnvironmentVariable($EnvVarName, "User")
Write-Host "Machine 级环境变量 : $(if ($MachineVal) { $MachineVal } else { '[空]' })"
Write-Host "User    级环境变量 : $(if ($UserVal)    { $UserVal    } else { '[空 - 正确]' })"

foreach ($path in @($PolicyPath64, $PolicyPath32, $PolicyPathCU)) {
    $val = (Get-ItemProperty -Path $path -Name "*" -ErrorAction SilentlyContinue)."*"
    Write-Host "策略注册表 $($path.Split('\')[-3..-1] -join '\') = $(if ($val) { $val } else { '[未写入]' })"
}

foreach ($path in $TauriPaths) {
    $pv = (Get-ItemProperty -Path $path -Name "pv" -ErrorAction SilentlyContinue).pv
    Write-Host "Tauri 检测注册表  $($path.Split('\')[-3..-1] -join '\') pv = $(if ($pv) { $pv } else { '[未写入]' })"
}

Write-Host "`n[完成] 请重启或注销重登以使环境变量在所有进程生效。" -ForegroundColor Yellow
