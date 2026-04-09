<div align="center">
<h1 align="center">choose-your-EdgeWebView2</h1>

[**English**](./README_EN.md) | **简体中文**

<p align="center">
你是否想彻底摆脱 Edge 的生态，并投入到 chrome / firefox 生态中，但是发现总有一些软件依赖于 msedgewebview2 ？

当你彻底删除 Windows 当中的 Edge ，却发现一些软件又自动安装了 msedgewebview2 ，之后附带着把 Edge 又安装了一次？

若你对本地的 msedgewebview2 有特殊定制要求，但是苦于软件无法默认识别你的指定版本？

**不用担心，本项目旨在解决这些问题，让 Windows 默认识别你自己的 msedgewebview2 。**
</p>
</div>

## 如何使用？
- 1.下载文件[**choose_msedgewebview2.ps1**](./choose_msedgewebview2.ps1) 或者 复制文件中的所有内容
- 2.右键使用管理员权限运行脚本，或者使用管理员权限打开 Powershell 粘贴脚本内容并回车。
- 3.根据提示，选择模式1，粘贴你的msedgewebview2.exe所在的相对路径并回车，例如：D:\Test\Microsoft.WebView2.FixedVersionRuntime.133.0.3065.92.x64
- 4.根据提示，选择是否需要锁定相应的环境变量和注册表。

## 锁定后，需要临时解锁？
- 在管理员权限运行脚本运行伊始，选择模式2，并根据提示粘贴并回车。

## 各层防御的作用说明

| 步骤            | 操作                                                 | 防御的逃逸场景                              |
| :------------ | :------------------------------------------------- | :----------------------------------- |
| 系统级环境变量写入     | `Machine` 级设置 `WEBVIEW2_BROWSER_EXECUTABLE_FOLDER` | 优先级高于注册表策略，确保 Loader 首先命中此值          |
| 清除 User 级环境变量 | 将 `User` 级设为 `$null`                               | 防止用户态的同名变量覆盖机器级设定                    |
| 注册表 ACL 锁定    | 拒绝 Users/NetworkService 对环境变量键写入                   | 防止低权限进程篡改 `HKLM\...\Environment` 中的值 |
| 策略注册表双路径      | 同时写 64位/WOW64/HKCU 三条路径                            | 覆盖 32位应用、用户级策略覆盖两种逃逸路径               |

执行完成后必须**重启或注销重新登录**，否则已运行的进程仍从旧的进程环境变量块中读取值 。
