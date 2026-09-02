$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\Users\karst\pop-setup\prepare.ps1 -SkipUsb -WindowsTargetGB 420"
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "karst"
$trigger.Delay = "PT1M"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 2)
$principal = New-ScheduledTaskPrincipal -UserId "karst" -RunLevel Highest -LogonType Interactive
Register-ScheduledTask -TaskName "pop-setup-shrink" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
"Aufgabe registriert: " + [bool](Get-ScheduledTask -TaskName "pop-setup-shrink" -ErrorAction SilentlyContinue) | Out-File "C:\Users\karst\pop-setup\register.txt" -Encoding utf8
