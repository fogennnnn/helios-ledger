# deploy-v13.ps1
# Save this + index_v13.html into C:\Users\fogen\HELIOS
# Run from C:\Users\fogen\HELIOS

Write-Host 'Deploying v13...' -ForegroundColor Cyan
if (-not (Test-Path 'index_v13.html')) { Write-Host 'ERROR: index_v13.html not found' -ForegroundColor Red; exit 1 }
Copy-Item -Path 'index_v13.html' -Destination 'docs\index.html' -Force
git add docs\index.html
git commit -m 'feat: token button flashes injected token, renamed to Token'
git push
Write-Host 'Done! https://ai.oooooooooo.se' -ForegroundColor Green
