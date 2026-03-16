# update8.ps1 - Fix terminal syntax error
# Run from C:\Users\fogen\HELIOS
# IMPORTANT: index_v8.html must be in the same folder as this script

Write-Host 'Copying index file...' -ForegroundColor Cyan

if (-not (Test-Path 'index_v8.html')) {
    Write-Host 'ERROR: index_v8.html not found in this folder!' -ForegroundColor Red
    Write-Host 'Make sure both update8.ps1 AND index_v8.html are in C:\Users\fogen\HELIOS' -ForegroundColor Yellow
    exit 1
}

Copy-Item -Path 'index_v8.html' -Destination 'docs\index.html' -Force

Write-Host 'Committing and pushing...' -ForegroundColor Cyan
git add docs\index.html
git commit -m 'fix: terminal JS no quotes in string literals, no syntax errors'
git push

Write-Host 'Done! https://ai.oooooooooo.se' -ForegroundColor Green
