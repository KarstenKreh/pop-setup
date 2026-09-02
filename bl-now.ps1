manage-bde -status C: | Select-String 'Conversion|Percentage' | ForEach-Object { $_.Line.Trim() } | Out-File "C:\Users\karst\pop-setup\bl-now.txt" -Encoding utf8
