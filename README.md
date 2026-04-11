<div align="center">
<h1 align="center">choose-your-EdgeWebView2</h1>

[**English**](./README_EN.md) | **简体中文**

<p align="center">
你是否想彻底摆脱 Edge，并投入到 Chrome / Firefox 生态中，但发现总有一些软件依赖于 msedgewebview2？

当你彻底删除 Windows 中的 Edge，却发现一些软件又自动安装了 msedgewebview2，之后附带着把 Edge 又装了一次？

若你对本地的 msedgewebview2 有特殊定制要求，但苦于软件无法默认识别你的指定版本？

**本项目旨在解决这些问题，让 Windows 默认识别你自己的 msedgewebview2。**
</p>
</div>

## 如何使用

1. [下载脚本文件](https://cdn.jsdelivr.net/gh/Xxx91n/choose-your-EdgeWebView2@refs/heads/main/choose_msedgewebview2.ps1)，或复制 [choose_msedgewebview2.ps1](./choose_msedgewebview2.ps1) 中的全部内容。
2. 右键以管理员身份运行脚本，或在管理员权限的 PowerShell 中粘贴内容并回车。
3. 选择界面语言（English / 简体中文）。
4. 选择**模式 1**，粘贴你的 msedgewebview2.exe 所在文件夹的完整路径并回车，例如：
   `D:\Test\Microsoft.WebView2.FixedVersionRuntime.133.0.3065.92.x64`
   脚本会自动验证路径并读取版本号，然后完成写入。

## 锁定注册表

若需要防止其他程序覆盖已写入的路径，在脚本启动后选择**模式 2**，即可为相应注册表路径加上 ACL 写入限制。

## 临时解锁

若需要修改或重新设置，在脚本启动后选择**模式 3**，即可移除 ACL 锁定，再使用模式 1 重新写入。

## 各层防御的作用说明

| 步骤 | 操作 | 防御的逃逸场景 |
| :--- | :--- | :--- |
| 系统级环境变量写入 | `Machine` 级设置 `WEBVIEW2_BROWSER_EXECUTABLE_FOLDER` | 优先级高于注册表策略，确保 Loader 首先命中此值 |
| 清除 User 级环境变量 | 将 `User` 级设为 `$null` | 防止用户态的同名变量覆盖机器级设定 |
| 注册表 ACL 锁定 | 拒绝 Users / NetworkService 对策略键写入 | 防止低权限进程篡改已写入的路径值 |
| 策略注册表多路径 | 同时写入 64 位 / WOW64 / HKCU 三条路径 | 覆盖 32 位应用、用户级策略覆盖两种逃逸路径 |
| Tauri 已安装记录 | 写入 EdgeUpdate Clients 注册表键 | 防止 Tauri 框架检测不到 WebView2 而触发自动安装 |

执行完成后必须**重启或注销重新登录**，否则已运行的进程仍从旧的进程环境变量块中读取值。
