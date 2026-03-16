# cleanup-and-restore.ps1
# Run from C:\Users\fogen\HELIOS

Write-Host "Step 1/3 - Moving working files to _working/ folder..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path _working | Out-Null
$files = @(
    "Ne.ps1","deploy-v2.ps1","deploy-worker.ps1","deploy-worker2.ps1",
    "index_clean.html","index_v10.html","index_v2.html","index_v4.html",
    "index_v5.html","index_v6.html","index_v7.html","index_v8.html",
    "index_v9.html","keygen.js","redesign.ps1","restore.ps1",
    "test-v2.ps1","test-v2b.ps1","update.ps1","update10.ps1",
    "update11.ps1","update2.ps1","update4.ps1","update5.ps1",
    "update6.ps1","update7.ps1","update8.ps1","update9.ps1",
    "worker-v2.js","worker.js","wrangler-v2.toml","wrangler.toml",
    "fix.ps1","setup.sh","cloudflare-dns-setup.md","deploy-v2b.ps1"
)
foreach ($f in $files) {
    if (Test-Path $f) { Move-Item -Path $f -Destination "_working\" -Force }
}
# Handle filenames with spaces/parens separately
if (Test-Path "index_v11 (1).html") { Move-Item -Path "index_v11 (1).html" -Destination "_working\" -Force }
if (Test-Path "update10 (1).ps1")   { Move-Item -Path "update10 (1).ps1"   -Destination "_working\" -Force }
Write-Host "  Done - all working files moved to _working/" -ForegroundColor Green

Write-Host "Step 2/3 - Restoring correct index.html (v11 clean design)..." -ForegroundColor Cyan
if (-not (Test-Path "index_v11.html")) {
    if (Test-Path "_working\index_v11.html") {
        Copy-Item -Path "_working\index_v11.html" -Destination "docs\index.html" -Force
        Write-Host "  Copied from _working\index_v11.html" -ForegroundColor Green
    } else {
        Write-Host "ERROR: index_v11.html not found anywhere!" -ForegroundColor Red
        exit 1
    }
} else {
    Copy-Item -Path "index_v11.html" -Destination "docs\index.html" -Force
    Write-Host "  Copied index_v11.html to docs\index.html" -ForegroundColor Green
}

git add docs\index.html
git diff --cached --stat

Write-Host "Step 3/3 - Committing and pushing..." -ForegroundColor Cyan
git commit -m "restore: v11 clean design, animated terminal, token generation button"
git push

Write-Host ""
Write-Host "All done!" -ForegroundColor Green
Write-Host "  Site:    https://ai.oooooooooo.se" -ForegroundColor Cyan
Write-Host "  Archive: _working/ folder" -ForegroundColor Gray
