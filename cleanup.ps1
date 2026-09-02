$out = "C:\Users\karst\pop-setup\cleanup.txt"
$lines = @("Start $(Get-Date -Format HH:mm)  frei vorher: $([math]::Round((Get-Volume C).SizeRemaining/1GB)) GB")
wsl --shutdown 2>&1 | Out-Null
wsl --unregister docker-desktop 2>&1 | Out-Null
Remove-Item -LiteralPath "C:\Users\karst\AppData\Local\Docker\wsl" -Recurse -Force -ErrorAction SilentlyContinue
$lines += "Docker-Daten weg: " + (-not (Test-Path "C:\Users\karst\AppData\Local\Docker\wsl"))
$nm = Get-ChildItem "C:\Users\karst\Documents\Repositories" -Directory -Recurse -Filter node_modules -Force -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\node_modules\\.*\\node_modules' }
$count = 0
foreach ($d in $nm) { Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction SilentlyContinue; if (-not (Test-Path -LiteralPath $d.FullName)) { $count++ } else { $lines += "blieb: " + $d.FullName } }
$lines += "node_modules geloescht: $count von $($nm.Count)"
foreach ($c in @("C:\Users\karst\AppData\Local\npm-cache","C:\Users\karst\AppData\Local\pnpm","C:\Users\karst\AppData\Local\pnpm-cache","C:\Users\karst\npm-cache","C:\Users\karst\.pnpm-cache","C:\Users\karst\.pnpm-state")) {
  Remove-Item -LiteralPath $c -Recurse -Force -ErrorAction SilentlyContinue
  $lines += "$c weg: " + (-not (Test-Path -LiteralPath $c))
}
$lines += "Ende $(Get-Date -Format HH:mm)  frei nachher: $([math]::Round((Get-Volume C).SizeRemaining/1GB)) GB"
$lines -join "`n" | Out-File $out -Encoding utf8
