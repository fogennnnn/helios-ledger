# update10.ps1 - Terminal: play once + static copyable commands + token injection
# Save this + index_v10.html into C:\Users\fogen\HELIOS
# Run from C:\Users\fogen\HELIOS

Write-Host 'Deploying terminal v2...' -ForegroundColor Cyan

if (-not (Test-Path 'index_v10.html')) {
    Write-Host 'ERROR: index_v10.html not found' -ForegroundColor Red; exit 1
}

Copy-Item -Path 'index_v10.html' -Destination 'docs\index.html' -Force
git add docs\index.html
git commit -m 'feat: terminal plays once then shows static copyable commands with token injection'
git push

Write-Host 'Done! https://ai.oooooooooo.se' -ForegroundColor Green
