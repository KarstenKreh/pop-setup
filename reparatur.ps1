$out = "C:\Users\karst\pop-setup\reparatur.txt"
$l = @()
try { Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -eq 'C:\Users\Reparatur' } | Remove-CimInstance; $l += "Profil entfernt: " + (-not (Test-Path C:\Users\Reparatur)) } catch { $l += "Profil-Fehler: " + $_.Exception.Message }
try { Remove-LocalUser -Name Reparatur; $l += "Konto entfernt: " + ($null -eq (Get-LocalUser Reparatur -ErrorAction SilentlyContinue)) } catch { $l += "Konto-Fehler: " + $_.Exception.Message }
$l -join "`n" | Out-File $out -Encoding utf8
