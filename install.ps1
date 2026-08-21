$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'DirectPaste.ps1'
$targetDirectory = Join-Path $env:LOCALAPPDATA 'DirectPaste'
$target = Join-Path $targetDirectory 'DirectPaste.ps1'

if (-not (Test-Path -LiteralPath $source)) { throw "DirectPaste.ps1 not found." }
New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $target -Force

$running = Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'powershell.exe' -and $_.CommandLine -match 'DirectPaste\\DirectPaste.ps1' }
foreach ($process in $running) { Stop-Process -Id $process.ProcessId -Force }

$command = 'powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -STA -File "' + $target + '"'
Set-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name DirectPaste -Value $command
Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList @('-NoProfile','-WindowStyle','Hidden','-ExecutionPolicy','Bypass','-STA','-File',$target) -WindowStyle Hidden

Write-Host 'DirectPaste installed and started.'
