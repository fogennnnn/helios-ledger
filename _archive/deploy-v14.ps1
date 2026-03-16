# deploy-v14.ps1
# Save this + index_v14.html into C:\Users\fogen\HELIOS

Write-Host 'Deploying v14 clean terminal...' -ForegroundColor Cyan
if (-not (Test-Path 'index_v14.html')) { Write-Host 'ERROR: index_v14.html not found' -ForegroundColor Red; exit 1 }
Copy-Item -Path 'index_v14.html' -Destination 'docs\index.html' -Force
git add docs\index.html
git commit -m 'feat: clean single-screen terminal, manual tabs, token flash'
git push
Write-Host 'Done! https://ai.oooooooooo.se' -ForegroundColor Green
