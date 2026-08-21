# DirectPaste

让 Windows 资源管理器可以直接用普通 `Ctrl+V` 将剪贴板截图保存为 PNG 文件。

## 工作方式

- 当前窗口是资源管理器、剪贴板为位图：保存为 `Snip_yyyyMMdd_HHmmss.png`。
- 当前位于微信、Word、浏览器等其他软件：不注册快捷键，软件直接接收原生 `Ctrl+V`。
- 资源管理器中复制的是普通文件：临时转交原本的 `Ctrl+V`，保持文件粘贴能力。
- 后台静默运行，登录 Windows 后自动启动。

支持 Snipaste 常见的 `Bitmap` / `DeviceIndependentBitmap` 剪贴板格式。

## 安装

右键 PowerShell，选择“使用 PowerShell 运行”，执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

安装完成后立即生效，无需重启。

## 卸载

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

## 注意

DirectPaste 只在资源管理器位于前台时注册 `Ctrl+V`；离开资源管理器后立即解除注册，不影响其他软件的原生粘贴。如果另一个软件也在资源管理器前台时全局占用 `Ctrl+V`，可能产生冲突。

## License

MIT
