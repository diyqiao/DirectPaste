Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$source = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public sealed class DirectPasteWindow : Form {
    const int WM_HOTKEY = 0x0312;
    const int HOTKEY_ID = 7301;
    const uint MOD_CONTROL = 0x0002;
    const uint VK_V = 0x56;
    readonly Timer foregroundTimer;
    bool registered;
    public event Action BitmapPasteRequested;

    [DllImport("user32.dll", SetLastError=true)] static extern bool RegisterHotKey(IntPtr window, int id, uint modifiers, uint key);
    [DllImport("user32.dll", SetLastError=true)] static extern bool UnregisterHotKey(IntPtr window, int id);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);

    public DirectPasteWindow() {
        foregroundTimer = new Timer();
        foregroundTimer.Interval = 100;
        foregroundTimer.Tick += delegate { UpdateRegistration(); };
        foregroundTimer.Start();
        UpdateRegistration();
    }

    static bool ExplorerIsForeground() {
        uint pid;
        GetWindowThreadProcessId(GetForegroundWindow(), out pid);
        try { return Process.GetProcessById((int)pid).ProcessName.Equals("explorer", StringComparison.OrdinalIgnoreCase); }
        catch { return false; }
    }

    void UpdateRegistration() {
        bool shouldRegister = ExplorerIsForeground();
        if (shouldRegister && !registered)
            registered = RegisterHotKey(Handle, HOTKEY_ID, MOD_CONTROL, VK_V);
        else if (!shouldRegister && registered) {
            UnregisterHotKey(Handle, HOTKEY_ID);
            registered = false;
        }
    }

    protected override void WndProc(ref Message message) {
        if (message.Msg == WM_HOTKEY && message.WParam.ToInt32() == HOTKEY_ID) {
            bool bitmap = false;
            try { bitmap = Clipboard.ContainsImage() && !Clipboard.ContainsFileDropList(); } catch {}
            if (ExplorerIsForeground() && bitmap) {
                if (BitmapPasteRequested != null) BitmapPasteRequested();
            } else {
                try {
                    UnregisterHotKey(Handle, HOTKEY_ID);
                    registered = false;
                    SendKeys.SendWait("^v");
                } finally {
                    UpdateRegistration();
                }
            }
            return;
        }
        base.WndProc(ref message);
    }

    protected override void SetVisibleCore(bool value) { base.SetVisibleCore(false); }
    protected override void Dispose(bool disposing) {
        foregroundTimer.Dispose();
        if (registered) UnregisterHotKey(Handle, HOTKEY_ID);
        base.Dispose(disposing);
    }
}
"@

Add-Type -TypeDefinition $source -ReferencedAssemblies 'System.Windows.Forms','System.Drawing'

function Get-ForegroundExplorerFolder {
    $foreground = [DirectPasteWindow]::GetForegroundWindow().ToInt64()
    $shell = New-Object -ComObject Shell.Application
    foreach ($window in $shell.Windows()) {
        try {
            if ([int64]$window.HWND -eq $foreground) {
                $path = $window.Document.Folder.Self.Path
                if ($path -and [IO.Directory]::Exists($path)) { return $path }
            }
        } catch {}
    }
    return [Environment]::GetFolderPath('Desktop')
}

function Save-ClipboardBitmap {
    try {
        $folder = Get-ForegroundExplorerFolder
        $image = [Windows.Forms.Clipboard]::GetImage()
        if ($null -eq $image) { return }
        $baseName = 'Snip_' + (Get-Date -Format 'yyyyMMdd_HHmmss')
        $path = Join-Path $folder ($baseName + '.png')
        $suffix = 1
        while ([IO.File]::Exists($path)) {
            $path = Join-Path $folder ($baseName + '_' + $suffix + '.png')
            $suffix++
        }
        try { $image.Save($path, [Drawing.Imaging.ImageFormat]::Png) }
        finally { $image.Dispose() }
    } catch {
        Add-Content -LiteralPath (Join-Path $env:LOCALAPPDATA 'DirectPaste\save-error.log') -Value ((Get-Date).ToString('s') + ' ' + $_.Exception.Message)
    }
}

$form = New-Object DirectPasteWindow
$form.add_BitmapPasteRequested({ Save-ClipboardBitmap })
[Windows.Forms.Application]::Run($form)


