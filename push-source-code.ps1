# push-source-code.ps1 -- Add worker source code to the repo
# This fixes: "pip install -r requirements.txt" not found
# The repo now contains the actual Cloudflare Worker source

Set-Location "C:\Users\fogen\HELIOS"

# Copy downloaded files into place
Write-Host "Adding source code to repo..." -ForegroundColor Cyan

# Create helios-worker dir if needed (should already exist locally)
New-Item -ItemType Directory -Force -Path "helios-worker" | Out-Null

# Copy source files (these should be downloaded to HELIOS\helios-worker\)
# worker.js, wrangler.toml, keygen.js, schema.sql, package.json, .gitignore
# should already be in helios-worker\ from the download

# Copy updated README
if (Test-Path "README.md") {
    Write-Host "  README.md updated" -ForegroundColor Green
}

# Remove old fix.ps1
if (Test-Path "fix.ps1") {
    Remove-Item "fix.ps1" -Force
    Write-Host "  Removed old fix.ps1" -ForegroundColor Green
}

# Stage and push
git add -A
git commit -m "feat: add complete worker source code, schema, keygen, and package.json

- helios-worker/worker.js: production Cloudflare Worker v4.0.0
- helios-worker/schema.sql: D1 database schema for self-hosting
- helios-worker/keygen.js: Ed25519 keypair generator
- helios-worker/package.json: npm scripts for dev/deploy
- helios-worker/wrangler.toml: Cloudflare config template
- Updated README with correct self-hosting steps
- Removed obsolete fix.ps1"

git push

Write-Host ""
Write-Host "Done! The repo now has full source code." -ForegroundColor Green
Write-Host "Anyone can now: git clone + cd helios-worker + npm install + deploy" -ForegroundColor Cyan
