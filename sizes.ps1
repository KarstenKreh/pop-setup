$out = "C:\Users\karst\pop-setup\sizes.txt"
function Measure-Dir($path) {
  $files = Get-ChildItem -LiteralPath $path -Recurse -File -Force -ErrorAction SilentlyContinue
  $logical = ($files | Measure-Object Length -Sum).Sum
  $local = ($files | Where-Object { -not ($_.Attributes -band 0x400000) -and -not ($_.Attributes -band 0x1000) } | Measure-Object Length -Sum).Sum
  "{0,8:N1} GB gesamt  {1,8:N1} GB lokal  {2}" -f ($logical/1GB), ($local/1GB), $path
}
$lines = @("--- Cloud-Ordner ---")
foreach ($p in @("C:\Users\karst\Proton Drive","C:\Users\karst\DK Tech Solutions UG","C:\Users\karst\SmartChange GmbH","C:\Users\karst\OneDrive")) { if (Test-Path -LiteralPath $p) { $lines += Measure-Dir $p } }
$lines += "--- C:\Users\karst\* ---"
Get-ChildItem "C:\Users\karst" -Directory -Force | Where-Object { -not ($_.Attributes -band 0x400) } | ForEach-Object { $lines += Measure-Dir $_.FullName }
$lines += "--- C:\* ---"
Get-ChildItem "C:\" -Directory -Force | Where-Object { $_.Name -ne 'Users' -and -not ($_.Attributes -band 0x400) } | ForEach-Object { $lines += Measure-Dir $_.FullName }
$lines -join "`n" | Out-File $out -Encoding utf8
