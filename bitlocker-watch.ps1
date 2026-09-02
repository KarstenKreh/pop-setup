do { Start-Sleep -Seconds 60; $s = (manage-bde -status C: | Out-String) } until ($s -match 'Fully Decrypted|Percentage Encrypted:\s+0')
"Fertig $(Get-Date -Format HH:mm)`n$s" | Out-File "C:\Users\karst\pop-setup\bitlocker-done.txt" -Encoding utf8
