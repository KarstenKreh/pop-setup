$out = "C:\Users\karst\pop-setup\unblock.txt"
$l = @("Start $(Get-Date -Format HH:mm)")
$l += (vssadmin list shadows 2>&1 | Select-String "Shadow Copy ID" | Measure-Object).Count.ToString() + " Schattenkopien vorher"
vssadmin delete shadows /all /quiet 2>&1 | Out-Null
$l += (vssadmin list shadows 2>&1 | Select-String "Shadow Copy ID" | Measure-Object).Count.ToString() + " Schattenkopien nachher"
$l += (fsutil usn deletejournal /D C: 2>&1 | Out-String).Trim()
$s = Get-PartitionSupportedSize -DriveLetter C
$l += "$(Get-Date -Format HH:mm) SizeMin GB: " + [math]::Round($s.SizeMin/1GB)
$l -join "`n" | Out-File $out -Encoding utf8
