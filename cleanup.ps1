$out = "C:\Users\karst\pop-setup\cleanup.txt"
$empty = "C:\Users\karst\pop-setup\empty"
New-Item -ItemType Directory -Force $empty | Out-Null
$lines = @("Start $(Get-Date -Format HH:mm)  frei vorher: $([math]::Round((Get-Volume C).SizeRemaining/1GB)) GB")

function Clear-Folder($path) {
  robocopy $empty $path /MIR /NFL /NDL /NJH /NJS /NP /R:0 /W:0 | Out-Null
  Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
}

$nm = Get-ChildItem "C:\Users\karst\Documents\Repositories" -Directory -Recurse -Filter node_modules -Force -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\node_modules\\' }
$lines += "node_modules gefunden: $($nm.Count)"
foreach ($d in $nm) { Clear-Folder $d.FullName }
$left = @(Get-ChildItem "C:\Users\karst\Documents\Repositories" -Directory -Recurse -Filter node_modules -Force -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\node_modules\\' }).Count
$lines += "node_modules uebrig: $left"

foreach ($c in @("C:\Users\karst\AppData\Local\npm-cache","C:\Users\karst\AppData\Local\pnpm","C:\Users\karst\AppData\Local\pnpm-cache","C:\Users\karst\npm-cache","C:\Users\karst\.pnpm-cache","C:\Users\karst\.pnpm-state")) {
  if (Test-Path -LiteralPath $c) { Clear-Folder $c }
  $lines += "$c weg: " + (-not (Test-Path -LiteralPath $c))
}
$lines += "Docker-Daten weg: " + (-not (Test-Path "C:\Users\karst\AppData\Local\Docker\wsl"))
Remove-Item $empty -Force -ErrorAction SilentlyContinue
$lines += "Ende $(Get-Date -Format HH:mm)  frei nachher: $([math]::Round((Get-Volume C).SizeRemaining/1GB)) GB"
$lines -join "`n" | Out-File $out -Encoding utf8
