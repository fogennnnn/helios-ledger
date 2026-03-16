Set-Location "C:\Users\fogen\HELIOS"
Copy-Item -Path "index.html" -Destination "docs\index.html" -Force
git add docs/index.html
git commit -m "ui: slow ticker by 20 pct for readability"
git push
Write-Host "Done! Reload https://ai.oooooooooo.se" -ForegroundColor Green
