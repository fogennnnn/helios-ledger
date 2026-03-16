# restore.ps1 - Restores clean design + token generation feature
# Save this + index_v11.html into C:\Users\fogen\HELIOS
# Run from C:\Users\fogen\HELIOS

Write-Host "Restoring clean design with token feature..." -ForegroundColor Cyan

if (-not (Test-Path "index_v11.html")) {
    Write-Host "ERROR: index_v11.html not found" -ForegroundColor Red; exit 1
}

Copy-Item -Path "index_v11.html" -Destination "docs\index.html" -Force
git add docs\index.html
git commit -m "restore: clean dark design + animated terminal + token generation"
git push

Write-Host "Done! https://ai.oooooooooo.se" -ForegroundColor Green
