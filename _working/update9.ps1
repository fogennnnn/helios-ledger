# update9.ps1 - Rotating headline banner
# Save BOTH this file AND index_v9.html into C:\Users\fogen\HELIOS then run
# Run from C:\Users\fogen\HELIOS

Write-Host 'Deploying rotating banner...' -ForegroundColor Cyan

if (-not (Test-Path 'index_v9.html')) {
    Write-Host 'ERROR: index_v9.html not found in this folder!' -ForegroundColor Red
    exit 1
}

Copy-Item -Path 'index_v9.html' -Destination 'docs\index.html' -Force
git add docs\index.html
git commit -m 'feat: rotating h1 banner with 7 headlines, 30s interval, dot nav'
git push

Write-Host 'Done! https://ai.oooooooooo.se' -ForegroundColor Green
