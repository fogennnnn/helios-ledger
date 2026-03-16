# deploy-v25b.ps1
# Run from C:\Users\fogen\HELIOS

Set-Location "C:\Users\fogen\HELIOS"
Write-Host "Deploying..." -ForegroundColor Cyan
if (-not (Test-Path "index_v25b.html")) { Write-Host "ERROR: index_v25b.html not found" -ForegroundColor Red; exit 1 }
Copy-Item -Path "index_v25b.html" -Destination "docs\index.html" -Force
git add docs\index.html
git commit -m "fix: remove demo language, call it what it is - real live ledger"
git push
Write-Host "Done! https://ai.oooooooooo.se" -ForegroundColor Green
