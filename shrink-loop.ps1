param([int]$TargetGB = 420, [int]$Rounds = 8)
$out = "C:\Users\karst\pop-setup\shrink-loop.txt"
$l = @("Start $(Get-Date -Format HH:mm)")
function Log($m) { $script:l += $m; $script:l -join "`n" | Out-File $out -Encoding utf8 }
function Blocker {
  $ev = Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='Microsoft-Windows-Defrag'; Id=259} -MaxEvents 1 -ErrorAction SilentlyContinue
  if ($ev) { (($ev.Message -split "`r?`n") | Select-String "unmovable file appears").Line.Trim() } else { "kein Ereignis" }
}
try {
  foreach ($name in @('OneDrive','ProtonDrive','Proton Mail','Discord','Spotify','TIDAL','WisprFlow','Wispr Flow','Docker Desktop','LM Studio','memozero','SearchHost','SearchIndexer')) {
    Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  }
  Log "Apps gestoppt"
  foreach ($n in @(6,5)) {
    $p = Get-Partition -DiskNumber 0 -PartitionNumber $n -ErrorAction SilentlyContinue
    if ($p -and $p.Size -lt 10GB) { Remove-Partition -DiskNumber 0 -PartitionNumber $n -Confirm:$false; Log "Partition $n entfernt" }
  }
  for ($i = 1; $i -le $Rounds; $i++) {
    fsutil usn deletejournal /D C: | Out-Null
    $sup = Get-PartitionSupportedSize -DriveLetter C
    $minGB = [math]::Ceiling($sup.SizeMin / 1GB)
    $cur = [math]::Floor((Get-Partition -DriveLetter C).Size / 1GB)
    $goal = [math]::Max($TargetGB, $minGB + 3)
    Log "Runde $i : aktuell $cur GB, SizeMin $minGB GB, Ziel $goal GB, Blocker: $(Blocker)"
    if ($goal -ge $cur - 2) { Log "Kein Fortschritt mehr moeglich"; break }
    Resize-Partition -DriveLetter C -Size ($goal * 1GB)
    Log "C: jetzt $([math]::Round((Get-Partition -DriveLetter C).Size/1GB)) GB"
    if ($goal -le $TargetGB) { break }
    Start-Sleep -Seconds 3
  }
  $dp = @"
select disk 0
create partition efi size=1024
format fs=fat32 quick label=POP_EFI
create partition primary size=4096
format fs=fat32 quick label=POPRECOVERY
create partition primary id=0FC63DAF-8483-4772-8E79-3D69D8477DE4
"@
  $dpFile = "C:\Users\karst\pop-setup\parts.txt"
  $dp | Out-File $dpFile -Encoding ascii
  $res = diskpart /s $dpFile
  Remove-Item $dpFile
  Log (($res | Where-Object { $_ -match 'succeeded|error|illegal|formatted' }) -join " | ")
  Get-Partition -DiskNumber 0 | ForEach-Object {
    if ($_.DriveLetter -and $_.DriveLetter -ne 'C') { try { Remove-PartitionAccessPath -DiskNumber 0 -PartitionNumber $_.PartitionNumber -AccessPath "$($_.DriveLetter):" } catch {} }
  }
  Log ((Get-Partition -DiskNumber 0 | ForEach-Object { "P$($_.PartitionNumber) $([math]::Round($_.Size/1GB,1)) GB $($_.GptType)" }) -join "`n")
} catch { Log ("FEHLER: " + $_.Exception.Message) }
Log "Ende $(Get-Date -Format HH:mm)"
