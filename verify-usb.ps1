$out = "C:\Users\karst\pop-setup\verify-usb.txt"
$iso = "C:\Users\karst\pop-setup\iso\pop-os_24.04_amd64_nvidia_27.iso"
$l = @("Start $(Get-Date -Format HH:mm)")
try {
  $len = (Get-Item $iso).Length
  $rd = New-Object IO.FileStream("\\.\PhysicalDrive1", 'Open', 'Read', 'ReadWrite', 1MB)
  $fs = [IO.File]::OpenRead($iso)
  foreach ($off in @(0, 1GB, 2GB, 3GB, ($len - 1MB))) {
    $a = New-Object byte[] 1MB; $b = New-Object byte[] 1MB
    $rd.Seek($off, 'Begin') | Out-Null; $fs.Seek($off, 'Begin') | Out-Null
    $rd.Read($a, 0, 1MB) | Out-Null; $fs.Read($b, 0, 1MB) | Out-Null
    $l += ("Offset {0,5} MB gleich: {1}" -f [math]::Round($off/1MB), [Linq.Enumerable]::SequenceEqual($a, $b))
  }
  $rd.Dispose(); $fs.Dispose()
} catch { $l += "FEHLER: " + $_.Exception.Message }
$l -join "`n" | Out-File $out -Encoding utf8
