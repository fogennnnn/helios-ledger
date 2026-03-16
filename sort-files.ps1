# sort-files.ps1 -- Moves downloaded files to their correct locations
# Run from C:\Users\fogen\HELIOS

Set-Location "C:\Users\fogen\HELIOS"

Write-Host "Sorting files into correct locations..." -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path "helios-worker" | Out-Null

# Files that belong in helios-worker\
$workerFiles = @("worker.js", "schema.sql", "keygen.js", "package.json", ".gitignore")
foreach ($f in $workerFiles) {
    if (Test-Path $f) {
        Move-Item -Path $f -Destination "helios-worker\$f" -Force
        Write-Host "  $f -> helios-worker\$f" -ForegroundColor Green
    }
}

# wrangler.toml — only move if helios-worker doesn't already have one with real DB ID
if (Test-Path "wrangler.toml") {
    if (Test-Path "helios-worker\wrangler.toml") {
        $existing = Get-Content "helios-worker\wrangler.toml" -Raw
        if ($existing -match "884d3be3") {
            Write-Host "  wrangler.toml -> SKIPPED (keeping existing with real DB ID)" -ForegroundColor Yellow
            Remove-Item "wrangler.toml" -Force
        } else {
            Move-Item -Path "wrangler.toml" -Destination "helios-worker\wrangler.toml" -Force
            Write-Host "  wrangler.toml -> helios-worker\wrangler.toml" -ForegroundColor Green
        }
    } else {
        Move-Item -Path "wrangler.toml" -Destination "helios-worker\wrangler.toml" -Force
        Write-Host "  wrangler.toml -> helios-worker\wrangler.toml" -ForegroundColor Green
    }
}

# README.md stays in root — just overwrite
if (Test-Path "README.md") {
    Write-Host "  README.md -> stays in root (ok)" -ForegroundColor Green
}

# Remove fix.ps1 if it still exists
if (Test-Path "fix.ps1") {
    Remove-Item "fix.ps1" -Force
    Write-Host "  fix.ps1 -> DELETED (obsolete)" -ForegroundColor Yellow
}

# Remove helios-worker folder if it got extracted as a subfolder with duplicates
if (Test-Path "helios-worker\helios-worker") {
    Get-ChildItem "helios-worker\helios-worker" | Move-Item -Destination "helios-worker\" -Force
    Remove-Item "helios-worker\helios-worker" -Recurse -Force
    Write-Host "  Flattened nested helios-worker\helios-worker\" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Now pushing to GitHub..." -ForegroundColor Cyan

git add -A
git commit -m "feat: add complete worker source code, schema, keygen, package.json

- helios-worker/worker.js: production Cloudflare Worker v4.0.0
- helios-worker/schema.sql: D1 database schema for self-hosting
- helios-worker/keygen.js: Ed25519 keypair generator
- helios-worker/package.json: npm scripts for dev/deploy
- Updated README with correct self-hosting steps
- Removed obsolete fix.ps1"

git push

Write-Host ""
Write-Host "Done! Repo now has full source code." -ForegroundColor Green
Write-Host "Verify: https://github.com/fogennnnn/helios-ledger" -ForegroundColor Cyan
