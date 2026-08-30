# 用于苹果妙控键盘的Windows

这是一个离线安装包，用于在 Windows 10/11 上安装 Apple 妙控键盘和妙控鼠标 2 的 Apple 签名驱动。

已针对以下设备标识制作：

- 妙控键盘：`VID_05AC&PID_0267`
- 妙控鼠标 2：`VID_05AC&PID_0269`

## 功能

- 安装妙控键盘 2/3 的 Apple 驱动。
- 安装妙控鼠标 2 的 Apple 驱动，启用触控滚动支持。
- 安装前核验固定 SHA-256 和 Apple Inc. 数字签名。
- 拉取仓库后可以离线安装。
- 不安装 PowerToys，不修改全局键位，因此不会影响普通 Windows 键盘。

## 可选：妙控键盘按键映射

驱动安装完成后，可选安装 AutoHotkey v2 映射层，让 Apple 键盘底排更符合 Windows 快捷键习惯：

| Apple 键帽 | Windows 行为 |
| --- | --- |
| Command | Ctrl |
| Control | Win |
| Option | Alt（保持不变） |

这样可以直接使用 `Command+C`、`Command+V`、`Command+Z`、`Command+Tab` 等常用快捷键。映射只在 `AppleMagicKeyboard.ahk` 运行时生效；退出 AutoHotkey 托盘菜单中的脚本即可恢复默认布局。由于 Windows 的普通键盘钩子不能可靠区分物理键盘设备，映射启用期间也会影响其他连接的 Windows 键盘。

1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)。
2. 以普通 PowerShell 运行以下命令，创建当前用户的开机自启并立即启用映射：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Install-AppleMagicKeyboardMapping.ps1
```

要移除开机自启，请运行：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Install-AppleMagicKeyboardMapping.ps1 -Remove
```

`Fn` 键由键盘硬件处理，AutoHotkey 无法单独识别它；功能键和媒体键行为仍由 Apple 驱动决定。


## 使用方法

先在管理员 PowerShell 中验证文件：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Install-AppleMagicWindows.ps1 -VerifyOnly
```

验证通过后安装：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Install-AppleMagicWindows.ps1
```

只安装键盘驱动：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Install-AppleMagicWindows.ps1 -SkipMouseDriver
```

只安装鼠标驱动：

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Install-AppleMagicWindows.ps1 -SkipKeyboardDriver
```

安装后如果功能没有立即生效，请重新插拔设备或重启 Windows。

## 安全说明

仓库中的驱动文件由 Apple Inc. 签名，但驱动二进制本身不是开源软件，所有权和许可条款归 Apple 所有。本仓库脚本不会关闭安全启动、不会启用测试签名模式，也不会安装未签名驱动。
