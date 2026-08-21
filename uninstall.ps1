$targetDirectory = Join-Path $env:LOCALAPPDATA 'DirectPaste'
$running = Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'powershell.exe' -and $_.CommandLine -match 'DirectPaste\\DirectPaste.ps1' }
foreach ($process in $running) { Stop-Process -Id $process.ProcessId -Force }
Remove-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name DirectPaste -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath $targetDirectory) { Remove-Item -LiteralPath $targetDirectory -Recurse -Force }
Write-Host 'DirectPaste uninstalled.'
