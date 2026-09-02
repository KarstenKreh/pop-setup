$out = "C:\Users\karst\pop-setup\bootfix.txt"
$l = @("Start $(Get-Date -Format HH:mm)")
$l += "--- Firmware-Eintraege vorher ---"
$fw = bcdedit /enum firmware | Out-String
$l += $fw
$entries = @()
$cur = $null
foreach ($line in ($fw -split "`r?`n")) {
  if ($line -match '^identifier\s+(\{[^}]+\})') { $cur = @{ id = $Matches[1]; desc = '' } ; $entries += $cur }
  elseif ($cur -and $line -match '^description\s+(.+)$') { $cur.desc = $Matches[1].Trim() }
}
$pop = $entries | Where-Object { $_.desc -match 'Pop|Linux|systemd|UEFI OS' -and $_.id -ne '{fwbootmgr}' } | Select-Object -First 1
if ($pop) {
  bcdedit /set '{fwbootmgr}' displayorder $pop.id /addfirst | Out-Null
  $l += "Pop-Eintrag '$($pop.desc)' $($pop.id) an erste Stelle gesetzt"
} else {
  $l += "KEIN Pop/Linux-Eintrag in der Firmware gefunden"
}
$l += "--- Reihenfolge nachher ---"
$l += (bcdedit /enum '{fwbootmgr}' | Out-String)
$l += "--- BitLocker ---"
$l += (manage-bde -status C: | Select-String 'Conversion|Percentage|Protection' | ForEach-Object { $_.Line.Trim() }) -join "`n"
$l += "--- EFI-Partitionen ---"
$l += (Get-Partition -DiskNumber 0 | Where-Object { $_.GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' } | ForEach-Object { "P$($_.PartitionNumber) $([math]::Round($_.Size/1MB)) MB" }) -join "`n"
$l += "--- HWiNFO Autostart ---"
$runKeys = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
foreach ($k in $runKeys) {
  $p = Get-ItemProperty $k -ErrorAction SilentlyContinue
  if ($p) { foreach ($n in ($p.PSObject.Properties | Where-Object { $_.Value -match 'HWiNFO' })) { Remove-ItemProperty $k -Name $n.Name; $l += "Run-Eintrag entfernt: $k\$($n.Name)" } }
}
Get-ScheduledTask | Where-Object { $_.TaskName -match 'HWiNFO' -or ($_.Actions | Where-Object { $_.Execute -match 'HWiNFO' }) } | ForEach-Object { Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath | Out-Null; $l += "Aufgabe deaktiviert: $($_.TaskPath)$($_.TaskName)" }
Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup","$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'HWiNFO' } | ForEach-Object { Remove-Item $_.FullName -Force; $l += "Autostart-Verknuepfung entfernt: $($_.FullName)" }
$l += "Ende $(Get-Date -Format HH:mm)"
$l -join "`n" | Out-File $out -Encoding utf8
