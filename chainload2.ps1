$out = "C:\Users\karst\pop-setup\chainload2.txt"
$l = @("Start $(Get-Date -Format HH:mm:ss)")
function Log($m) { $script:l += $m; $script:l -join "`n" | Out-File $out -Encoding utf8 }
try {
  $efiType = '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
  $winEsp = Get-Partition -DiskNumber 0 | Where-Object { $_.GptType -eq $efiType -and $_.Size -lt 500MB } | Select-Object -First 1
  $popEsp = Get-Partition -DiskNumber 0 | Where-Object { $_.GptType -eq $efiType -and $_.Size -gt 500MB } | Select-Object -First 1
  if (-not $winEsp.DriveLetter) { Add-PartitionAccessPath -DiskNumber 0 -PartitionNumber $winEsp.PartitionNumber -AccessPath 'W:' }
  if (-not $popEsp.DriveLetter) { Add-PartitionAccessPath -DiskNumber 0 -PartitionNumber $popEsp.PartitionNumber -AccessPath 'P:' }
  Start-Sleep -Seconds 2

  $sdb = 'P:\EFI\systemd\systemd-bootx64.efi'
  if (-not (Test-Path $sdb)) { throw "systemd-boot fehlt auf P:" }
  $popMs = 'P:\EFI\Microsoft\Boot'
  if (-not (Test-Path "$popMs\bootmgfw.efi")) { throw "Windows-Kopie fehlt auf P:" }
  if (-not (Test-Path "$popMs\bootmgfw_real.efi")) { Copy-Item "$popMs\bootmgfw.efi" "$popMs\bootmgfw_real.efi" }
  Copy-Item $sdb "$popMs\bootmgfw.efi" -Force
  Log "P: bootmgfw.efi ist jetzt systemd-boot, echter Windows-Loader liegt als bootmgfw_real.efi daneben"

  $winMs = 'W:\EFI\Microsoft\Boot'
  if (Test-Path "$winMs\bootmgfw.efi") {
    if (-not (Test-Path "$winMs\bootmgfw_real.efi")) { Copy-Item "$winMs\bootmgfw.efi" "$winMs\bootmgfw_real.efi" }
    Remove-Item "$winMs\bootmgfw.efi" -Force
    Log "W: bootmgfw.efi versteckt (liegt als bootmgfw_real.efi weiter dort)"
  } else { Log "W: bootmgfw.efi war schon weg" }

  New-Item -ItemType Directory -Force 'P:\loader\entries' | Out-Null
  $enc = New-Object Text.UTF8Encoding $false
  [IO.File]::WriteAllText('P:\loader\loader.conf', "default Pop_OS-current`ntimeout 5`nauto-entries 0`nconsole-mode max`n", $enc)
  [IO.File]::WriteAllText('P:\loader\entries\windows.conf', "title Windows 11`nefi /EFI/Microsoft/Boot/bootmgfw_real.efi`n", $enc)
  Log ("loader.conf: " + ((Get-Content 'P:\loader\loader.conf') -join ' | '))
  Log ("Eintraege: " + ((Get-ChildItem 'P:\loader\entries' | Select-Object -ExpandProperty Name) -join ', '))
  Log ("Pop-Eintrag: " + ((Get-Content 'P:\loader\entries\Pop_OS-current.conf' | Select-Object -First 3) -join ' | '))

  Remove-PartitionAccessPath -DiskNumber 0 -PartitionNumber $winEsp.PartitionNumber -AccessPath 'W:' -ErrorAction SilentlyContinue
  Remove-PartitionAccessPath -DiskNumber 0 -PartitionNumber $popEsp.PartitionNumber -AccessPath 'P:' -ErrorAction SilentlyContinue
} catch { Log ("FEHLER: " + $_.Exception.Message) }
Log "Ende $(Get-Date -Format HH:mm:ss)"
