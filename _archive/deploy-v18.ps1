# deploy-v18.ps1
# Save this + index_v18.html into C:\Users\fogen\HELIOS

Write-Host 'Deploying...' -ForegroundColor Cyan
if (-not (Test-Path 'index_v18.html')) { Write-Host 'ERROR: index_v18.html not found' -ForegroundColor Red; exit 1 }
Copy-Item -Path 'index_v18.html' -Destination 'docs\index.html' -Force
git add docs\index.html
git commit -m 'feat: token reveal badge + copy on click'
git push
Write-Host 'Done! https://ai.oooooooooo.se' -ForegroundColor Green
