# full-repair.ps1 -- Helios Ledger full production repair
# 1. Deploys fixed worker v4 (fixes POST /api/v1/records 500)
# 2. Updates README to match actual architecture
# 3. Runs end-to-end validation

Set-Location "C:\Users\fogen\HELIOS"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  HELIOS LEDGER FULL PRODUCTION REPAIR" -ForegroundColor Cyan  
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Deploy fixed worker ─────────────────────────────────────────
Write-Host "[Step 1/3] Deploying worker v4..." -ForegroundColor Yellow

Set-Location "C:\Users\fogen\HELIOS\helios-worker"

if (-not (Test-Path "worker-v4.js")) {
    Write-Host "ERROR: worker-v4.js not found in helios-worker\" -ForegroundColor Red
    Write-Host "Download it from Claude and place it here first." -ForegroundColor Yellow
    exit 1
}

Copy-Item -Path "worker-v4.js" -Destination "worker.js" -Force
npx wrangler deploy

if ($LASTEXITCODE -ne 0) {
    Write-Host "Worker deploy failed!" -ForegroundColor Red
    exit 1
}
Write-Host "Worker v4 deployed." -ForegroundColor Green
Write-Host ""

# ── Step 2: Update repo README ──────────────────────────────────────────
Write-Host "[Step 2/3] Updating GitHub repo..." -ForegroundColor Yellow

Set-Location "C:\Users\fogen\HELIOS"

if (Test-Path "README.md") {
    Copy-Item -Path "README.md" -Destination "README.md.bak" -Force
}

# Copy the new README (should be downloaded from Claude to HELIOS root)
if (Test-Path "README-v4.md") {
    Copy-Item -Path "README-v4.md" -Destination "README.md" -Force
    git add README.md
    git commit -m "docs: update README to match production architecture (v4)"
    git push
    Write-Host "README updated and pushed." -ForegroundColor Green
} else {
    Write-Host "README-v4.md not found, skipping repo update." -ForegroundColor Yellow
    Write-Host "  (Place README-v4.md in HELIOS root to update docs)" -ForegroundColor Gray
}
Write-Host ""

# ── Step 3: Quick smoke test ────────────────────────────────────────────
Write-Host "[Step 3/3] Running smoke test..." -ForegroundColor Yellow
Write-Host ""

Start-Sleep -Seconds 3

# Health check
Write-Host "  Testing GET /api/v1/health..." -ForegroundColor Gray
try {
    $health = Invoke-RestMethod "https://ai.oooooooooo.se/api/v1/health"
    Write-Host "    Status: $($health.status), Version: $($health.version), Records: $($health.record_count)" -ForegroundColor Green
} catch {
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Create account
Write-Host "  Testing POST /api/v1/accounts..." -ForegroundColor Gray
$testUser = "repair_test_" + (Get-Random -Maximum 999999)
try {
    $body = @{ username = $testUser } | ConvertTo-Json
    $acct = Invoke-RestMethod "https://ai.oooooooooo.se/api/v1/accounts" -Method POST -ContentType "application/json" -Body $body
    Write-Host "    Account created: $($acct.username), chain_record index: $($acct.chain_record.merkle_index)" -ForegroundColor Green
} catch {
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# THE CRITICAL TEST: Submit record
Write-Host "  Testing POST /api/v1/records (THE FIX)..." -ForegroundColor Gray
try {
    $headers = @{ Authorization = "Bearer $($acct.token)" }
    $body = @{ content = "Repair validation test $(Get-Date -Format o)"; model = "repair-test" } | ConvertTo-Json
    $rec = Invoke-RestMethod "https://ai.oooooooooo.se/api/v1/records" -Method POST -ContentType "application/json" -Headers $headers -Body $body
    Write-Host "    RECORD CREATED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "    ID:          $($rec.id)" -ForegroundColor Cyan
    Write-Host "    Hash:        $($rec.content_hash)" -ForegroundColor Cyan
    Write-Host "    Merkle idx:  $($rec.merkle_index)" -ForegroundColor Cyan
    Write-Host "    Root:        $($rec.merkle_root)" -ForegroundColor Cyan
} catch {
    Write-Host "    STILL FAILING: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "    Check the error response for diagnostic info (E:xxx prefix)." -ForegroundColor Yellow
    exit 1
}

# Verify the record
Write-Host "  Testing GET /api/v1/records/{id}/verify..." -ForegroundColor Gray
try {
    $v = Invoke-RestMethod "https://ai.oooooooooo.se/api/v1/records/$($rec.id)/verify"
    Write-Host "    Verified: valid=$($v.valid), proof_depth=$($v.proof_depth)" -ForegroundColor Green
} catch {
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  REPAIR COMPLETE" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Run the full E2E test suite:" -ForegroundColor Cyan
Write-Host "  powershell -ExecutionPolicy Bypass -File test-e2e.ps1" -ForegroundColor Gray
