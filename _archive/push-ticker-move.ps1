# push-ticker-move.ps1 -- Move use-case ticker to hero section
# Run from C:\Users\fogen\HELIOS

Set-Location "C:\Users\fogen\HELIOS"

Write-Host "Updating site with ticker in hero..." -ForegroundColor Cyan

if (-not (Test-Path "index.html")) {
    Write-Host "ERROR: index.html not found in HELIOS root" -ForegroundColor Red
    Write-Host "Download it from Claude first." -ForegroundColor Yellow
    exit 1
}

Copy-Item -Path "index.html" -Destination "docs\index.html" -Force

git add docs/index.html
git commit -m "ui: move use-case ticker to hero section, full-bleed between buttons and stats"
git push

Write-Host ""
Write-Host "Done! Reload https://ai.oooooooooo.se in ~30s" -ForegroundColor Green
