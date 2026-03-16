# deploy-v20.ps1
# Save this + index_v20.html into C:\Users\fogen\HELIOS

Write-Host 'Deploying...' -ForegroundColor Cyan
if (-not (Test-Path 'index_v20.html')) { Write-Host 'ERROR: index_v20.html not found' -ForegroundColor Red; exit 1 }
Copy-Item -Path 'index_v20.html' -Destination 'docs\index.html' -Force
git add docs\index.html
git commit -m 'feat: $TOKEN badge with flash + TOKEN copied toast notification'
git push
Write-Host 'Done! https://ai.oooooooooo.se' -ForegroundColor Green
