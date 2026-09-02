$cs = Get-CimInstance Win32_ComputerSystem
Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile=$true}
Set-Service WSearch -StartupType Automatic
Start-Service WSearch -ErrorAction SilentlyContinue
"Pagefile auto: " + (Get-CimInstance Win32_ComputerSystem).AutomaticManagedPagefile + "  WSearch: " + (Get-Service WSearch).StartType | Out-File "C:\Users\karst\pop-setup\restore.txt" -Encoding utf8
