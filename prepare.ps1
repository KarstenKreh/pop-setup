param(
  [int]$WindowsTargetGB = 600,
  [int]$UsbDiskNumber = 1,
  [switch]$SkipShrink,
  [switch]$SkipUsb
)
$ErrorActionPreference = 'Stop'
$base = "C:\Users\karst\pop-setup"
$iso = "$base\iso\pop-os_24.04_amd64_nvidia_27.iso"
$expectedSha = "2c68c26edb5d1c55472fe415086917b2deec8a09689944717b6a16a45bc88f10"
$report = "$base\prepare.txt"
$log = @()
function Log($m) { $script:log += $m; Write-Host $m; $script:log -join "`n" | Out-File $report -Encoding utf8 }

try {
  Log "Start $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

  Log "--- ISO pruefen ---"
  $sha = (Get-FileHash $iso -Algorithm SHA256).Hash.ToLower()
  if ($sha -ne $expectedSha) { throw "ISO-Pruefsumme falsch: $sha" }
  Log "ISO ok: $sha"

  Log "--- Ruhezustand und Schnellstart aus ---"
  powercfg /h off | Out-Null
  Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name HiberbootEnabled -Value 0 -Type DWord
  Log "hiberfil weg, Fast Startup aus"

  if (-not $SkipShrink) {
    Log "--- C: verkleinern ---"
    $part = Get-Partition -DriveLetter C
    $sup = Get-PartitionSupportedSize -DriveLetter C
    $minGB = [math]::Ceiling($sup.SizeMin / 1GB)
    $targetGB = [math]::Max($WindowsTargetGB, $minGB + 20)
    Log "SizeMin $minGB GB, Ziel $targetGB GB"
    if ($targetGB -lt [math]::Floor($part.Size / 1GB) - 10) {
      Resize-Partition -DriveLetter C -Size ($targetGB * 1GB)
      Log "C: ist jetzt $([math]::Round((Get-Partition -DriveLetter C).Size/1GB)) GB"
    } else {
      Log "Kein Shrink noetig oder moeglich"
    }

    Log "--- Linux-Partitionen anlegen ---"
    $diskNumber = $part.DiskNumber
    $dp = @"
select disk $diskNumber
create partition efi size=1024
format fs=fat32 quick label=POP_EFI
create partition primary size=4096
format fs=fat32 quick label=POP_RECOVERY
create partition primary id=0FC63DAF-8483-4772-8E79-3D69D8477DE4
"@
    $dpFile = "$base\parts.txt"
    $dp | Out-File $dpFile -Encoding ascii
    diskpart /s $dpFile | ForEach-Object { Log $_ }
    Remove-Item $dpFile
    Get-Partition -DiskNumber $diskNumber | ForEach-Object {
      if ($_.DriveLetter -and $_.DriveLetter -ne 'C') {
        try { Remove-PartitionAccessPath -DiskNumber $diskNumber -PartitionNumber $_.PartitionNumber -AccessPath "$($_.DriveLetter):" } catch {}
      }
    }
    Get-Partition -DiskNumber $diskNumber | Select-Object PartitionNumber, DriveLetter, @{n='GB';e={[math]::Round($_.Size/1GB,1)}}, GptType | Out-String | ForEach-Object { Log $_ }
  }

  if (-not $SkipUsb) {
    Log "--- USB-Stick beschreiben ---"
    $usb = Get-Disk -Number $UsbDiskNumber
    if ($usb.BusType -ne 'USB') { throw "Disk $UsbDiskNumber ist kein USB-Geraet ($($usb.BusType)). Abbruch." }
    if ($usb.Size -gt 200GB) { throw "Disk $UsbDiskNumber ist zu gross fuer einen Stick. Abbruch." }
    Log "Stick: $($usb.FriendlyName), $([math]::Round($usb.Size/1GB)) GB"
    Get-Partition -DiskNumber $UsbDiskNumber -ErrorAction SilentlyContinue | ForEach-Object {
      if ($_.DriveLetter) { try { Remove-PartitionAccessPath -DiskNumber $UsbDiskNumber -PartitionNumber $_.PartitionNumber -AccessPath "$($_.DriveLetter):" } catch {} }
    }
    Clear-Disk -Number $UsbDiskNumber -RemoveData -RemoveOEM -Confirm:$false
    Set-Disk -Number $UsbDiskNumber -IsOffline $true
    Set-Disk -Number $UsbDiskNumber -IsReadOnly $false
    $src = [IO.File]::Open($iso, 'Open', 'Read', 'Read')
    $dst = New-Object IO.FileStream("\\.\PhysicalDrive$UsbDiskNumber", 'Open', 'Write', 'None', 4MB, 'WriteThrough')
    $buf = New-Object byte[] (4MB)
    $total = 0; $sw = [Diagnostics.Stopwatch]::StartNew()
    while (($n = $src.Read($buf, 0, $buf.Length)) -gt 0) {
      if ($n -lt $buf.Length) { $pad = [math]::Ceiling($n / 512) * 512; [Array]::Clear($buf, $n, $pad - $n); $n = $pad }
      $dst.Write($buf, 0, $n); $total += $n
      if ($total % 256MB -eq 0) { Write-Host ("{0:N0} MB" -f ($total/1MB)) }
    }
    $dst.Flush(); $dst.Dispose(); $src.Dispose()
    Log "Geschrieben: $([math]::Round($total/1MB)) MB in $([math]::Round($sw.Elapsed.TotalSeconds)) s"

    Log "--- Rueckpruefung ---"
    $isoLen = (Get-Item $iso).Length
    $rd = New-Object IO.FileStream("\\.\PhysicalDrive$UsbDiskNumber", 'Open', 'Read', 'None', 4MB)
    $hasher = [Security.Cryptography.SHA256]::Create()
    $left = $isoLen; $buf = New-Object byte[] (4MB)
    while ($left -gt 0) {
      $n = $rd.Read($buf, 0, [math]::Min($buf.Length, $left))
      if ($n -le 0) { break }
      $hasher.TransformBlock($buf, 0, $n, $null, 0) | Out-Null
      $left -= $n
    }
    $hasher.TransformFinalBlock($buf, 0, 0) | Out-Null
    $rd.Dispose()
    $stickSha = ([BitConverter]::ToString($hasher.Hash) -replace '-', '').ToLower()
    Set-Disk -Number $UsbDiskNumber -IsOffline $false
    if ($stickSha -ne $expectedSha) { throw "Stick-Pruefsumme falsch: $stickSha" }
    Log "Stick verifiziert, Pruefsumme stimmt"
  }

  Log "FERTIG $(Get-Date -Format 'HH:mm')"
} catch {
  Log "FEHLER: $($_.Exception.Message)"
  Log $_.ScriptStackTrace
}
