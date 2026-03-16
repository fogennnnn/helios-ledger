# deploy-v25.ps1
# Run from C:\Users\fogen\HELIOS

Set-Location "C:\Users\fogen\HELIOS"
Write-Host "Deploying v25 - clean shell tabs..." -ForegroundColor Cyan
if (-not (Test-Path "index_v25.html")) { Write-Host "ERROR: index_v25.html not found" -ForegroundColor Red; exit 1 }
Copy-Item -Path "index_v25.html" -Destination "docs\index.html" -Force
git add docs\index.html
git commit -m "fix: shell tabs JS rewritten cleanly, no escaping issues"
git push
Write-Host "Done! https://ai.oooooooooo.se" -ForegroundColor Green
