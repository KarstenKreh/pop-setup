$s = Get-PartitionSupportedSize -DriveLetter C
"$(Get-Date -Format HH:mm) SizeMin GB: " + [math]::Round($s.SizeMin/1GB) + "  frei: " + [math]::Round((Get-Volume C).SizeRemaining/1GB) | Out-File "C:\Users\karst\pop-setup\sizemin.txt" -Encoding utf8
