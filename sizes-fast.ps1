$out = "C:\Users\karst\pop-setup\sizes-fast.txt"
$lines = @()
function RoboSize($p) {
  $r = robocopy $p "C:\__null__" /L /S /BYTES /NFL /NDL /NJH /NP /XJ /R:0 /W:0 2>$null
  $m = ($r | Select-String '^\s*Bytes\s*:\s*(\d+)').Matches
  if ($m.Count -gt 0) { [double]$m[0].Groups[1].Value } else { 0 }
}
$targets = @()
$targets += Get-ChildItem "C:\" -Directory -Force | Where-Object { $_.Name -ne 'Users' -and -not ($_.Attributes -band 0x400) }
$targets += Get-ChildItem "C:\Users\karst" -Directory -Force | Where-Object { -not ($_.Attributes -band 0x400) }
foreach ($d in $targets) { $lines += "{0,8:N1} GB  {1}" -f ((RoboSize $d.FullName)/1GB), $d.FullName }
$lines += "{0,8:N1} GB  {1}" -f ((Get-ChildItem "C:\" -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum/1GB), "C:\ (Dateien direkt, inkl. pagefile)"
$lines | Sort-Object -Descending | Out-File $out -Encoding utf8
