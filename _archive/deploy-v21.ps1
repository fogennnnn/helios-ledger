# deploy-v21.ps1
# Save this + index_v21.html into C:\Users\fogen\HELIOS

Write-Host 'Deploying...' -ForegroundColor Cyan
if (-not (Test-Path 'index_v21.html')) { Write-Host 'ERROR: index_v21.html not found' -ForegroundColor Red; exit 1 }
Copy-Item -Path 'index_v21.html' -Destination 'docs\index.html' -Force
git add docs\index.html
git commit -m 'fix: clipboard copy using execCommand, toast + button feedback'
git push
Write-Host 'Done! https://ai.oooooooooo.se' -ForegroundColor Green
