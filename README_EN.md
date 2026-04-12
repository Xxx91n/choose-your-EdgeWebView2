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

1. Open PowerShell as Administrator and run the following command.

```powershell
[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;[Console]::InputEncoding=[System.Text.Encoding]::UTF8;$OutputEncoding=[System.Text.Encoding]::UTF8;iex(irm https://cdn.jsdelivr.net/gh/Xxx91n/choose-your-EdgeWebView2@refs/heads/main/choose_msedgewebview2.ps1)
```

> **Why the three extra segments?**
> When using `iex(irm ...)`, PowerShell compiles the entire downloaded script string before executing it. If the console encoding is still the system default (e.g. GBK) at that point, Chinese string literals in the script are already decoded incorrectly during compilation — the UTF-8 encoding lines inside the script run too late to fix this. Setting the encoding before `iex` ensures the script is compiled correctly.

2. Select the interface language (English / Simplified Chinese).
3. Select **Mode 1**, paste the full path to the folder containing `msedgewebview2.exe`, and press Enter. For example:
   `D:\Test\Microsoft.WebView2.FixedVersionRuntime.133.0.3065.92.x64`
   The script will validate the path, auto-detect the version, and complete all write operations.

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

## Using the Debug Script

If the main script fails to run, use the included [debug_choose_msedgewebview2.ps1](./debug_choose_msedgewebview2.ps1) to diagnose the issue.

**Steps:**
1. Place `debug_choose_msedgewebview2.ps1` in the **same folder** as `choose_msedgewebview2.ps1`.
2. Run it from an elevated PowerShell session:
   ```powershell
   .\debug_choose_msedgewebview2.ps1
   ```
3. The debug script runs the following checks sequentially and writes all output to a timestamped `debug_log_*.txt` file in the same directory:

   | Check | Description |
   | :--- | :--- |
   | CHECK 0 | Administrator privilege detection |
   | CHECK 1 | PowerShell version ≥ 5.0 |
   | CHECK 2 | Current execution policy (CurrentUser / LocalMachine scopes) |
   | CHECK 3 | Main script file presence in the same directory |
   | CHECK 4 | Main script AST syntax parse — reports exact error line numbers |
   | CHECK 5 | Read-only registry path accessibility check (no writes performed) |
   | CHECK 6 | Current environment variable state (Machine / User / Process scopes) |
   | CHECK 7 | Live execution of the main script with Tee-Object mirroring output to the log |

4. When filing an issue, attach the generated `debug_log_*.txt` file.

## Application Fails to Recognize the Configured WebView2 Runtime?

Some applications, upon failing to detect a system-registered WebView2 runtime, will **automatically download and install** the latest msedgewebview2 over the network — potentially pulling Edge back in the process.

**If you find that an application does not correctly recognize the path configured by this script:**

1. **Disconnect from the network immediately** to prevent the application from triggering its auto-download logic.
2. Open an [Issue](https://github.com/Xxx91n/choose-your-EdgeWebView2/issues) and include:
   - Application name and version
   - Contents of the `debug_log_*.txt` log file
   - Application source (official website / GitHub link, etc.)

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
