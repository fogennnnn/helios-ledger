# deploy-v26.ps1
# Run from C:\Users\fogen\HELIOS

Set-Location "C:\Users\fogen\HELIOS"
Write-Host "Deploying v26..." -ForegroundColor Cyan
if (-not (Test-Path "index_v26.html")) { Write-Host "ERROR: index_v26.html not found" -ForegroundColor Red; exit 1 }
Copy-Item -Path "index_v26.html" -Destination "docs\index.html" -Force
git add docs\index.html
git commit -m "feat: live record count, scrolling ticker, live Merkle panel"
git push
Write-Host "Done! https://ai.oooooooooo.se" -ForegroundColor Green
