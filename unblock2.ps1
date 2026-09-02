$out = "C:\Users\karst\pop-setup\unblock2.txt"
$l = @("Start $(Get-Date -Format HH:mm)")
Stop-Service WSearch -Force -ErrorAction SilentlyContinue
Set-Service WSearch -StartupType Disabled
$idx = "C:\ProgramData\Microsoft\Search\Data\Applications\Windows"
Get-ChildItem $idx -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
$l += "Suchindex weg: " + (-not (Test-Path "$idx\Windows.db"))
$cs = Get-CimInstance Win32_ComputerSystem
if ($cs.AutomaticManagedPagefile) { Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile=$false} }
Get-CimInstance Win32_PageFileSetting | Remove-CimInstance -ErrorAction SilentlyContinue
$l += "Auslagerungsdatei abgeschaltet (wirkt nach Neustart)"
$s = Get-PartitionSupportedSize -DriveLetter C
$l += "$(Get-Date -Format HH:mm) SizeMin GB: " + [math]::Round($s.SizeMin/1GB)
$ev = Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='Microsoft-Windows-Defrag'; Id=259} -MaxEvents 1
$l += (($ev.Message -split "`r?`n") | Select-String "unmovable file appears").Line.Trim()
$l -join "`n" | Out-File $out -Encoding utf8
