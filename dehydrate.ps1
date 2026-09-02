$out = "C:\Users\karst\pop-setup\dehydrate.txt"
$lines = @()
foreach ($p in @("C:\Users\karst\Proton Drive","C:\Users\karst\DK Tech Solutions UG","C:\Users\karst\SmartChange GmbH","C:\Users\karst\OneDrive")) {
  if (-not (Test-Path -LiteralPath $p)) { continue }
  $t = [Diagnostics.Stopwatch]::StartNew()
  attrib +U -P /S /D "$p\*" 2>&1 | Out-Null
  $files = Get-ChildItem -LiteralPath $p -Recurse -File -Force -ErrorAction SilentlyContinue
  $local = ($files | Where-Object { -not ($_.Attributes -band 0x400000) } | Measure-Object Length -Sum).Sum
  $lines += "{0}: {1} Dateien, noch lokal {2:N1} GB, {3} s" -f $p, $files.Count, ($local/1GB), [math]::Round($t.Elapsed.TotalSeconds)
}
$lines -join "`n" | Out-File $out -Encoding utf8
