# AHK toolbox

一组面向 Windows 的 AutoHotkey v2 快捷键工具。既可以运行统一入口一次启用全部功能，
也可以只运行需要的单个模块。

## 快速开始

1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)；本仓库不支持 v1。
2. 下载仓库，或使用 Git 克隆：

   ```powershell
   git clone https://github.com/leixin0725/AHK_toolbox.git
   cd AHK_toolbox
   ```

3. 双击 `KeysRedirect.ahk`。

默认配置无需修改即可加载。未安装的可选应用只会在触发对应快捷键时提示启动失败，
不会影响其他模块。不要同时运行统一入口和它已经包含的单个模块，否则相同快捷键会由
两个进程重复处理。

需要开机启动时，为 `KeysRedirect.ahk` 创建快捷方式，按 `Win+R` 打开 `shell:startup`，
再把快捷方式放入该目录。

## 默认快捷键

| 快捷键 | 功能 | 额外依赖 |
| --- | --- | --- |
| 短按 `CapsLock` | 发送 `Esc` | 无 |
| 按住 `CapsLock` | 作为左 `Ctrl` | 无 |
| `ScrollLock` / `Pause` | 映射为 `F14` / `F15` | 无 |
| Copilot 键（`F23` 或 `Win+Shift+F23`） | 映射为右 `Ctrl`，并修正 Win/Shift 卡键 | 带 Copilot 键的键盘 |
| `PrintScreen` / `F13` | 呼出、隐藏或启动 Obsidian | Obsidian；跨虚拟桌面移动另需 DLL |
| `Ctrl+Shift+Insert` | 呼出全部 Git Bash 窗口；再次触发全部最小化 | Git for Windows |
| `Ctrl+Shift+Alt+Insert` | 新建 Git Bash 窗口 | Git for Windows |
| `Win+Insert` | 呼出全部 Windows Terminal 窗口；再次触发全部最小化 | Windows Terminal |
| `Win+Alt+Insert` | 新建 Windows Terminal 窗口 | Windows Terminal |
| `Ctrl+Alt+G` | 跨虚拟桌面呼出、隐藏或启动 Chrome（含 PWA / 应用模式窗口） | Chrome；跨虚拟桌面移动另需 DLL |
| `Win+F` | 切换 ScratchEditor | ScratchEditor |

`ScrollLock` 只负责映射 `F14`；ScratchEditor 使用 `Win+F`，两者不会争用同一个按键。
终端新建窗口时会优先采用最近使用的文件资源管理器目录，无法获取时回退到“文档”目录。

## 按需运行

不需要统一入口时，可以直接运行任意根目录模块：

| 文件 | 职责 |
| --- | --- |
| `capslock-tap-esc-ctrl.ahk` | CapsLock 双角色键 |
| `scroll-pause-function-keys.ahk` | F14 / F15 扩展键 |
| `copilot-to-ctrl.ahk` | Copilot 键映射 |
| `obsidian-toggle.ahk` | Obsidian 窗口切换 |
| `git-bash-toggle.ahk` | Git Bash 窗口切换 |
| `windows-terminal-toggle.ahk` | Windows Terminal 窗口切换 |
| `chrome-toggle.ahk` | Chrome 窗口切换 |
| `scratch-editor.ahk` | ScratchEditor IPC 客户端 |

这些文件名和根目录位置作为兼容入口保留。终端模块内部共享 `lib/terminal-toggle.ahk`，
Obsidian 与 Chrome 共享 `lib/virtual-desktop.ahk`；不需要单独运行 `lib` 下的文件。

## 配置

仓库默认值集中在 `config/settings.ahk`。不要直接把自己的路径写进这个文件；先复制本地
覆盖模板：

```powershell
Copy-Item .\config\settings.local.example.ahk .\config\settings.local.ahk
```

然后取消所需行的注释并修改。`settings.local.ahk` 已被 Git 忽略，更新仓库时不会覆盖。
常用选项包括：

- `Enable...`：启用或禁用模块。
- `...Hotkey` / `ObsidianHotkeys`：修改应用快捷键。
- `GitBashExecutable`、`WindowsTerminalExecutable`、`ChromeExecutable`：指定程序路径。
- `ObsidianLauncher`：指定自定义启动器；可用于自行实现启动、退出后备份等工作流。
- `VirtualDesktopAccessorDll`：指定可选虚拟桌面 DLL。
- `TerminalFallbackDirectory`：没有可用文件资源管理器窗口时的终端目录。
- `ScratchEditorExecutable`、`ScratchEditorServerName`：ScratchEditor 安装位置和生产管道名。

配置优先级为：仓库默认值 < `settings.local.ahk` < ScratchEditor 对应环境变量。
ScratchEditor 支持现有的 `SCRATCHEDITOR_EXE` 和 `SCRATCHEDITOR_SERVER_NAME`；环境变量仅在
非空时覆盖本地配置。

AutoHotkey 热键符号中，`^`、`!`、`+`、`#` 分别代表 Ctrl、Alt、Shift、Win。
例如 `!^g` 是 `Ctrl+Alt+G`。修改热键后重新加载脚本生效。

## ScratchEditor 集成

[ScratchEditor](https://github.com/leixin0725/ScratchEditor) 是独立的开源 Qt 编辑器项目，
本仓库只负责全局快捷键、后台预热和本地 IPC 调度，不包含或复制它的源码及二进制文件。

默认情况下，AHK 客户端连接生产命名管道 `ScratchEditor.Stage1.v1`，并在需要时启动：

```text
%LOCALAPPDATA%\ScratchEditor\AhkEditor\ScratchEditor.exe --background
```

按下 `Win+F` 后，客户端会先复用现有管道；未运行时启动常驻实例并等待就绪，然后发送
`toggle`。若程序缺失、启动超时或 IPC 失败，只显示短暂提示，不读取或改写剪贴板。

ScratchEditor 当前需要从源码构建。请以其上游 README 为准；典型安装流程为：

```powershell
git clone https://github.com/leixin0725/ScratchEditor.git
cd ScratchEditor
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\restore-toolchain.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Preset release
```

上游构建脚本会部署供 AHK 使用的稳定副本。若你采用其他安装位置，在
`settings.local.ahk` 修改 `ScratchEditorExecutable`，或设置 `SCRATCHEDITOR_EXE`。

本仓库只使用上游公开的生产行为：`--background`、状态探测和 `toggle`。测试模式、迁移阶段
开关与测试专用 `quit` 命令不属于本仓库接口。

## Obsidian、Chrome 与虚拟桌面

普通的启动、呼出和最小化不需要额外 DLL。脚本会自动查找常见 Obsidian 和 Chrome 安装路径，
也可在本地配置中指定 `ObsidianExecutable`、`ObsidianLauncher` 或 `ChromeExecutable`。Chrome
浏览器、PWA 与应用模式窗口使用相同的跨桌面切换行为。

跨虚拟桌面移动其他进程窗口需要
[Ciantic/VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor)。从其
[Releases](https://github.com/Ciantic/VirtualDesktopAccessor/releases) 下载与你的 Windows
版本兼容的 `VirtualDesktopAccessor.dll`，放到仓库的 `lib` 目录，或配置完整路径。
该项目当前版本面向 Windows 11 24H2 及更新版本，Windows 更新可能改变未公开的虚拟桌面接口，
因此应优先使用其最新版本。

DLL 缺失、加载失败或接口不兼容时，脚本不会猜测窗口归属，也不会把用户带到其他虚拟桌面；
它会退回 Windows 文档化的 `IVirtualDesktopManager`，只处理能确认位于当前桌面的窗口。

## 常见问题

### 脚本提示需要 AutoHotkey v2

确认安装的是 v2，并使用 v2 的可执行文件打开 `.ahk`。本仓库使用 v2 的函数、类和热键语法。

### 快捷键触发两次或修饰键异常

检查托盘区域是否同时运行了 `KeysRedirect.ahk` 和相同的独立模块。退出重复实例后重新加载
统一入口。

### 应用无法启动

先确认应用本身可以正常启动，再在 `settings.local.ahk` 配置完整路径。Git Bash 和 Chrome
会检查常见安装位置，Windows Terminal 默认通过 `wt.exe` 启动。

### 管理员窗口中快捷键无效

Windows 通常不允许普通权限进程向更高权限窗口注入输入。仅在确有需要时以管理员身份运行
AHK 脚本；Chrome 和普通 Obsidian 启动会通过 Explorer 尽量保持普通权限。

### ScratchEditor 一直提示启动失败

检查 `ScratchEditor.exe` 是否位于默认稳定目录，或配置 `SCRATCHEDITOR_EXE`。若自定义了
`SCRATCHEDITOR_SERVER_NAME`，ScratchEditor 实例与本脚本必须使用相同值。

## 许可

本仓库采用 [MIT License](LICENSE)。ScratchEditor 和 VirtualDesktopAccessor 是独立项目，
分别遵循各自仓库声明的许可。
