<div align="center">
<h1 align="center">choose-your-EdgeWebView2</h1>

**English** | [**简体中文**](./README.md)

<p align="center">
Do you want to completely break free from Edge and embrace the Chrome / Firefox ecosystem, but find that some software still depends on msedgewebview2?

After fully removing Edge from Windows, do you find that some software automatically reinstalls msedgewebview2, and Edge gets pulled back along with it?

Do you have custom requirements for your local msedgewebview2, but software can't recognize your specified version by default?

**This project aims to solve these problems by making Windows recognize your own msedgewebview2 by default.**
</p>
</div>

## How to Use
1. [Download the script](https://cdn.jsdelivr.net/gh/Xxx91n/choose-your-EdgeWebView2@refs/heads/main/choose_msedgewebview2.ps1), then open PowerShell with administrator privileges and run the following command.

```powershell
cd <path to script>
.\choose_msedgewebview2.ps1
```
Or copy the contents of [choose_msedgewebview2.ps1](https://github.com/Xxx91n/choose-your-EdgeWebView2/blob/main/choose_msedgewebview2.ps1) and paste to run.

2. Select the interface language (English / Simplified Chinese).

3. Select **Mode 1**, paste the full path to the folder containing msedgewebview2.exe and press Enter, for example:
   `D:\Test\Microsoft.WebView2.FixedVersionRuntime.133.0.3065.92.x64`
   The script will automatically validate the path, read the version number, and complete the write operation.

## Lock the Registry

To prevent other programs from overwriting the written path, select **Mode 2** after launching the script to add ACL write restrictions to the corresponding registry paths.

## Temporary Unlock

To modify or reset the configuration, select **Mode 3** after launching the script to remove the ACL lock, then use Mode 1 to rewrite.

## Software Tested and Confirmed Working

The following software has been verified to correctly recognize the custom msedgewebview2 via this script:

- [pot](https://github.com/pot-app/pot-desktop)
- [bypass](https://www.bypass.cn/)
- [NetEase UU Remote](https://uuyc.163.com/)
- [clash-verge-rev](https://github.com/clash-verge-rev/clash-verge-rev)
- [OpenCode Desktop](https://opencode.ai/)

## Explanation of Each Defense Layer

| Step | Operation | Escape Scenario Defended Against |
| :--- | :--- | :--- |
| System-level environment variable write | Set `WEBVIEW2_BROWSER_EXECUTABLE_FOLDER` at `Machine` scope | Higher priority than registry policy, ensures the Loader hits this value first |
| Clear User-level environment variable | Set `User` scope to `$null` | Prevents a same-named user-scope variable from overriding the machine-level setting |
| Registry ACL lock | Deny write access to policy keys for Users / NetworkService | Prevents low-privilege processes from tampering with the written path value |
| Registry multi-path policy | Write to 64-bit / WOW64 / HKCU paths simultaneously | Covers 32-bit applications and user-level policy override escape paths |
| Tauri installed record | Write to EdgeUpdate Clients registry key | Prevents the Tauri framework from failing to detect WebView2 and triggering an automatic installation |

After execution, you must **restart or log out and log back in**, otherwise already-running processes will still read values from the old process environment variable block.

## How to Fix Execution Policy Errors

If the following error appears when running the script:

```
File ...choose_msedgewebview2.ps1 cannot be loaded because running scripts is disabled on this system.
```

This is a PowerShell execution policy restriction. The following two methods are recommended:

**Method 1 (Recommended): Bypass the execution policy for a single run without changing system settings**

Run the following command in an administrator PowerShell — it only applies to this execution and does not change the system policy:

```powershell
PowerShell -ExecutionPolicy Bypass -File ".\choose_msedgewebview2.ps1"
```

**Method 2: Modify the execution policy for the current user**

Run the following command in an administrator PowerShell to permanently allow running locally-signed scripts:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

After execution, re-run the script. To revert, replace `RemoteSigned` with `Restricted` and run again.

## How to Use the Debug Script

If the main script cannot run normally, use the [debug_choose_msedgewebview2.ps1](https://cdn.jsdelivr.net/gh/Xxx91n/choose-your-EdgeWebView2@refs/heads/main/debug_choose_msedgewebview2.ps1) included in the repository for diagnosis.

**Steps:**
1. Place `debug_choose_msedgewebview2.ps1` and `choose_msedgewebview2.ps1` in the **same folder**.
2. Execute in an administrator PowerShell:
   ```powershell
   .\debug_choose_msedgewebview2.ps1
   ```
3. The debug script will perform the following checks in sequence and write all output to a `debug_log_<timestamp>.txt` log file in the same directory:

   | Check | Content |
   | :--- | :--- |
   | CHECK 0 | Administrator privilege detection |
   | CHECK 1 | Whether PowerShell version is ≥ 5.0 |
   | CHECK 2 | Current execution policy (CurrentUser / LocalMachine) |
   | CHECK 3 | Whether the main script file exists in the same directory |
   | CHECK 4 | Main script syntax parsing (AST), accurately reports the error line number |
   | CHECK 5 | Read-only accessibility of all registry paths (no writes) |
   | CHECK 6 | Current state of environment variables (Machine / User / Process three layers) |
   | CHECK 7 | Actually launches the main script, using Tee-Object to simultaneously write interactive output to the log |

4. When submitting an issue, please attach the generated `debug_log_*.txt` file.

## A Specific App Cannot Recognize the WebView2 Path Set by the Script?

Some software, when it cannot detect the system WebView2, will **automatically download and install** the latest version of msedgewebview2 online (and pull Edge back along with it).

**If you find that a particular app cannot correctly recognize the path you specified via this script:**

1. **Immediately disconnect from the network** to prevent the software from triggering its automatic download and installation logic.
2. Go to [Issues](https://github.com/Xxx91n/choose-your-EdgeWebView2/issues) and submit an issue, including:
   - Software name and version number
   - Contents of the `debug_log_*.txt` log file
   - The source of the software installation (official website link / GitHub, etc.)

---

## Optional Enhancement: Disable WebView2 Telemetry

The project includes [kill_tele.reg](./kill_tele.reg), which writes the following restrictions via Windows Group Policy registry entries:

- Disable Edge / WebView2 experiment and configuration service communication
- Disable diagnostic data, crash reports, and metrics reporting
- Disable SmartScreen (which queries Microsoft servers for URLs)
- Disable network prediction
- Disable the global Windows telemetry switch

Double-click `kill_tele.reg` and confirm the import. This operation does not affect the functionality of `choose_msedgewebview2.ps1` and is an independent privacy enhancement option.

---

## Related Tools Reference

The following are commonly used companion tools in the community; choose as needed. **This project assumes no responsibility for the results of using the tools below. Please assess the risks yourself.**

**Block Windows 11 from automatically updating/installing Edge and EdgeWebView2 at the system level:**
Note: This operation will affect normal Windows 11 updates and Microsoft Store functionality.
- [Windows Update Blocker](https://www.sordum.org/9470/windows-update-blocker-v1-8/)

**Completely remove installed Edge and EdgeWebView2:**
The following two PowerShell scripts can both be used to uninstall residual Edge components:
- [EdgeRemover](https://github.com/he3als/EdgeRemover)
- [Remove-MS-Edge](https://github.com/ShadowWhisperer/Remove-MS-Edge)

**Get a portable version of Edge that stays version-synced and blocks automatic updates:**
If you need to use a portable version of Edge rather than the system-installed version:
- [edge-portable-chrome-next-mini](https://github.com/bibicadotnet/edge-portable-chrome-next-mini)

## Contributing

Submit an [issue](https://github.com/Xxx91n/choose-your-EdgeWebView2/issues) or [PR](https://github.com/Xxx91n/choose-your-EdgeWebView2/pulls).

## License

[MIT License](./LICENSE)
