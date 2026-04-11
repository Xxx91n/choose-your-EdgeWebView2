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
4. 选择**模式 1**，粘贴 msedgewebview2.exe 所在文件夹的完整路径并回车，例如：
   `D:\Test\Microsoft.WebView2.FixedVersionRuntime.133.0.3065.92.x64`
   脚本会自动验证路径并读取版本号，然后完成写入。

## 执行策略报错的解决方法

若运行脚本时出现以下错误：

```
无法加载文件 ...choose_msedgewebview2.ps1，因为在此系统上禁止运行脚本。
```

这是 PowerShell 执行策略限制，有以下两种推荐解决方法：

**方法一（推荐）：绕过执行策略直接运行，不修改系统设置**

在管理员权限的 PowerShell 中运行以下命令，只对本次执行生效，不改变系统策略：

```powershell
PowerShell -ExecutionPolicy Bypass -File ".\choose_msedgewebview2.ps1"
```

**方法二：修改当前用户的执行策略**

在管理员权限的 PowerShell 中运行以下命令，永久允许运行本地签名脚本：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

执行后重新运行脚本即可。如需还原，将 `RemoteSigned` 替换为 `Restricted` 重新执行即可。

## 锁定注册表

若需防止其他程序覆盖已写入的路径，在脚本启动后选择**模式 2**，即可为相应注册表路径添加 ACL 写入限制。

## 临时解锁

若需修改或重新设置，在脚本启动后选择**模式 3**，即可移除 ACL 锁定，再使用模式 1 重新写入。

## 已测试可正常运行的软件

以下软件均已验证可通过本脚本正常识别自定义 msedgewebview2：

- [pot](https://github.com/pot-app/pot-desktop)
- [bypass](https://www.bypass.cn/)
- [网易UU远程](https://uuyc.163.com/)
- [clash-verge-rev](https://github.com/clash-verge-rev/clash-verge-rev)
- [OpenCode Desktop](https://opencode.ai/)

## 各层防御的作用说明

| 步骤 | 操作 | 防御的逃逸场景 |
| :--- | :--- | :--- |
| 系统级环境变量写入 | `Machine` 级设置 `WEBVIEW2_BROWSER_EXECUTABLE_FOLDER` | 优先级高于注册表策略，确保 Loader 首先命中此值 |
| 清除 User 级环境变量 | 将 `User` 级设为 `$null` | 防止用户态的同名变量覆盖机器级设定 |
| 注册表 ACL 锁定 | 拒绝 Users / NetworkService 对策略键写入 | 防止低权限进程篡改已写入的路径值 |
| 策略注册表多路径 | 同时写入 64 位 / WOW64 / HKCU 三条路径 | 覆盖 32 位应用、用户级策略覆盖两种逃逸路径 |
| Tauri 已安装记录 | 写入 EdgeUpdate Clients 注册表键 | 防止 Tauri 框架检测不到 WebView2 而触发自动安装 |

执行完成后必须**重启或注销重新登录**，否则已运行的进程仍从旧的进程环境变量块中读取值。

---

## 可选增强：关闭 WebView2 遥测

项目附带 [kill_tele.reg](./kill_tele.reg)，通过 Windows 组策略注册表写入以下限制：

- 关闭 Edge / WebView2 的实验和配置服务通信
- 禁用诊断数据、崩溃报告、指标上报
- 禁用 SmartScreen（会向微软服务器查询 URL）
- 关闭网络预测
- 关闭 Windows 全局遥测开关

双击 `kill_tele.reg` 并确认导入即可。此操作不影响 `choose_msedgewebview2.ps1` 的功能，属于独立的隐私增强选项。

---

## 相关工具参考

以下为社区中常见的配套工具，可根据需要自行选择使用。**本项目不对以下工具的使用结果承担任何责任，请自行评估风险。**

**禁止 Windows 11 自动更新/安装 Edge 和 EdgeWebView2**
注意：此操作会影响 Windows 11 系统正常更新和微软应用商店的功能。
- [Windows Update Blocker](https://www.sordum.org/9470/windows-update-blocker-v1-8/)

**彻底清除已安装的 Edge 和 EdgeWebView2**
以下两个 PowerShell 脚本均可用于卸载残留的 Edge 组件：
- [EdgeRemover](https://github.com/he3als/EdgeRemover)
- [Remove-MS-Edge](https://github.com/ShadowWhisperer/Remove-MS-Edge)

**获取便携版 Edge 并保持版本同步**
若需使用便携版 Edge 而非系统安装版：
- [microsoft-edge-multi-portable](https://github.com/bibicadotnet/microsoft-edge-multi-portable)
