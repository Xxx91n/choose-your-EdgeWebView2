<div align="center">
<h1 align="center">choose-your-EdgeWebView2</h1>

**English** | [**简体中文**](./README.md)

<p align="center">
Do you want to completely move away from Edge and adopt the Chrome / Firefox ecosystem, but find that certain applications still depend on msedgewebview2?

After uninstalling Edge from Windows, do some applications silently reinstall msedgewebview2 — and pull Edge back along with it?

Do you have specific customization requirements for your local msedgewebview2 runtime, but the applications cannot recognize your designated version by default?

**This project solves these problems by forcing Windows to recognize your own msedgewebview2 runtime.**
</p>
</div>

## How to Use

1. [Download the script](https://cdn.jsdelivr.net/gh/Xxx91n/choose-your-EdgeWebView2@refs/heads/main/choose_msedgewebview2.ps1), or copy the full contents of [choose_msedgewebview2.ps1](./choose_msedgewebview2.ps1).
2. Right-click and run as Administrator, or paste the contents into an elevated PowerShell session and press Enter.
3. Select the interface language (English / Simplified Chinese).
4. Select **Mode 1**, paste the full path to the folder containing `msedgewebview2.exe`, and press Enter. For example:
   `D:\Test\Microsoft.WebView2.FixedVersionRuntime.133.0.3065.92.x64`
   The script will validate the path, auto-detect the version, and complete all write operations.

## Resolving Execution Policy Errors

If you encounter the following error when running the script:

```
File ...choose_msedgewebview2.ps1 cannot be loaded because running scripts is disabled on this system.
```

This is caused by the PowerShell execution policy. Two recommended solutions are provided below:

**Option 1 (Recommended): Bypass execution policy for this run only — no system-wide changes**

Run the following command in an elevated PowerShell session. This applies only to the current invocation and does not alter the system policy:

```powershell
PowerShell -ExecutionPolicy Bypass -File ".\choose_msedgewebview2.ps1"
```

**Option 2: Set the execution policy for the current user**

Run the following command in an elevated PowerShell session to permanently allow locally created scripts:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Re-run the script afterward. To revert, replace `RemoteSigned` with `Restricted` and run the command again.

## Locking the Registry

To prevent other processes from overwriting the configured path, select **Mode 2** at startup. This applies Deny ACL entries to the relevant registry keys, restricting write access for low-privileged accounts.

## Unlocking

To modify or reconfigure the settings, select **Mode 3** at startup to remove the ACL restrictions, then use Mode 1 to rewrite the values.

## Verified Compatible Applications

The following applications have been confirmed to work correctly with a custom msedgewebview2 runtime configured via this script:

- [pot](https://github.com/pot-app/pot-desktop)
- [bypass](https://www.bypass.cn/)
- [NetEase UU Remote](https://uuyc.163.com/)
- [clash-verge-rev](https://github.com/clash-verge-rev/clash-verge-rev)
- [OpenCode Desktop](https://opencode.ai/)

## Defense Layer Reference

| Step | Operation | Threat Scenario Mitigated |
| :--- | :--- | :--- |
| Machine-level environment variable | Set `WEBVIEW2_BROWSER_EXECUTABLE_FOLDER` at `Machine` scope | Takes precedence over registry policy; ensures the WebView2 Loader resolves this value first |
| Clear User-level environment variable | Set `User` scope to `$null` | Prevents a user-scope variable of the same name from shadowing the machine-scope value |
| Registry ACL lock | Deny `SetValue`, `Delete`, `CreateSubKey` for Users / NetworkService on policy keys | Prevents low-privileged processes from overwriting the configured path |
| Multi-path policy registry | Write to 64-bit, WOW64, and HKCU paths simultaneously | Covers 32-bit application loading and user-level policy override escape paths |
| Tauri installation record | Write `pv` and `name` values to EdgeUpdate Clients registry key | Prevents the Tauri framework from triggering an automatic WebView2 installation when it cannot detect a registered runtime |

After execution, you must **restart or log off and back in** — processes already running will continue to read from their inherited environment variable block until relaunched.

---

## Optional Enhancement: Suppress WebView2 Telemetry

The repository includes [kill_tele.reg](./kill_tele.reg), which writes the following restrictions via Windows Group Policy registry entries:

- Disables the Edge / WebView2 Experimentation and Configuration Service
- Disables diagnostic data collection, crash reporting, and metrics reporting
- Disables SmartScreen (which queries Microsoft servers for URL reputation)
- Disables network prediction
- Sets the Windows global telemetry level to off

Double-click `kill_tele.reg` and confirm the import. This is independent of the main script and has no effect on its functionality.

---

## Related Tools

The following are community tools that are commonly used alongside this project. **This project assumes no responsibility for any consequences arising from the use of these tools. Evaluate the risks independently before proceeding.**

**Block Windows 11 from automatically installing Edge and EdgeWebView2**
Note: This will also block Windows 11 system updates and Microsoft Store functionality.
- [Windows Update Blocker](https://www.sordum.org/9470/windows-update-blocker-v1-8/)

**Completely remove existing Edge and EdgeWebView2 installations**
Two PowerShell-based removal scripts are available:
- [EdgeRemover](https://github.com/he3als/EdgeRemover)
- [Remove-MS-Edge](https://github.com/ShadowWhisperer/Remove-MS-Edge)

**Obtain a portable Edge build and keep it up to date**
For users who prefer a portable runtime over a system installation:
- [microsoft-edge-multi-portable](https://github.com/bibicadotnet/microsoft-edge-multi-portable)
