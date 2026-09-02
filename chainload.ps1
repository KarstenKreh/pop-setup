$out = "C:\Users\karst\pop-setup\chainload.txt"
$l = @("Start $(Get-Date -Format HH:mm)")
function Log($m) { $script:l += $m; $script:l -join "`n" | Out-File $out -Encoding utf8 }
try {
  $efiType = '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
  $winEsp = Get-Partition -DiskNumber 0 | Where-Object { $_.GptType -eq $efiType -and $_.Size -lt 500MB } | Select-Object -First 1
  $popEsp = Get-Partition -DiskNumber 0 | Where-Object { $_.GptType -eq $efiType -and $_.Size -gt 500MB } | Select-Object -First 1
  Log "Windows-ESP P$($winEsp.PartitionNumber), Pop-ESP P$($popEsp.PartitionNumber)"
  foreach ($pair in @(@($winEsp, 'W'), @($popEsp, 'P'))) {
    $p = $pair[0]; $letter = $pair[1]
    if (-not $p.DriveLetter) { Add-PartitionAccessPath -DiskNumber 0 -PartitionNumber $p.PartitionNumber -AccessPath "${letter}:" }
  }
  Start-Sleep -Seconds 2
  Log ("Pop-ESP Inhalt: " + ((Get-ChildItem P:\EFI -Directory | Select-Object -ExpandProperty Name) -join ', '))
  if (-not (Test-Path 'P:\EFI\systemd\systemd-bootx64.efi')) { throw "systemd-boot fehlt auf der Pop-ESP" }
  robocopy 'W:\EFI\Microsoft' 'P:\EFI\Microsoft' /E /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
  Log ("Windows-Bootdateien kopiert: " + (Test-Path 'P:\EFI\Microsoft\Boot\bootmgfw.efi'))
  $conf = 'P:\loader\loader.conf'
  $txt = if (Test-Path $conf) { Get-Content $conf -Raw } else { '' }
  if ($txt -match '(?m)^timeout\s') { $txt = $txt -replace '(?m)^timeout\s.*$', 'timeout 5' } else { $txt = $txt.TrimEnd() + "`ntimeout 5`n" }
  [IO.File]::WriteAllText($conf, $txt, (New-Object Text.UTF8Encoding $false))
  Log ("loader.conf: " + ((Get-Content $conf) -join ' | '))
  Log ("Eintraege: " + ((Get-ChildItem P:\loader\entries -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) -join ', '))
  bcdedit /set '{bootmgr}' device 'partition=P:' | Out-Null
  bcdedit /set '{bootmgr}' path '\EFI\systemd\systemd-bootx64.efi' | Out-Null
  Log "Firmware-Eintrag 'Windows Boot Manager' zeigt jetzt auf systemd-boot der Pop-ESP"
  bcdedit /set '{fwbootmgr}' displayorder '{5500b88f-a706-11f1-8882-806e6f6e6963}' /addlast 2>$null | Out-Null
  Log ((bcdedit /enum '{bootmgr}' | Out-String).Trim())
  Remove-PartitionAccessPath -DiskNumber 0 -PartitionNumber $winEsp.PartitionNumber -AccessPath 'W:' -ErrorAction SilentlyContinue
  Remove-PartitionAccessPath -DiskNumber 0 -PartitionNumber $popEsp.PartitionNumber -AccessPath 'P:' -ErrorAction SilentlyContinue
} catch { Log ("FEHLER: " + $_.Exception.Message) }
Log "Ende $(Get-Date -Format HH:mm)"
