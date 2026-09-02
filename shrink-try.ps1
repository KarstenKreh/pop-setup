param([int]$TargetGB = 300)
$out = "C:\Users\karst\pop-setup\shrink-try.txt"
$l = @("Start $(Get-Date -Format HH:mm)")
try {
  fsutil usn deletejournal /D C: | Out-Null
  $l += "Journal geloescht"
  $sup = Get-PartitionSupportedSize -DriveLetter C
  $minGB = [math]::Ceiling($sup.SizeMin / 1GB)
  $goal = [math]::Max($TargetGB, $minGB + 5)
  $l += "SizeMin $minGB GB, Ziel $goal GB"
  Resize-Partition -DriveLetter C -Size ($goal * 1GB)
  $l += "C: ist jetzt $([math]::Round((Get-Partition -DriveLetter C).Size/1GB)) GB"
} catch {
  $l += "FEHLER: " + $_.Exception.Message
}
$ev = Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='Microsoft-Windows-Defrag'; Id=259} -MaxEvents 1 -ErrorAction SilentlyContinue
if ($ev) { $l += (($ev.Message -split "`r?`n") | Select-String "unmovable file appears").Line.Trim() }
$l += "Ende $(Get-Date -Format HH:mm)"
$l -join "`n" | Out-File $out -Encoding utf8
