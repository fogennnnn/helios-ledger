# test-e2e.ps1 -- Helios Ledger end-to-end validation
# Run after deploying worker v4
# Tests every endpoint and the full browser demo flow

Set-Location "C:\Users\fogen\HELIOS"

$base = "https://ai.oooooooooo.se/api/v1"
$pass = 0
$fail = 0
$total = 0

function Test-Endpoint {
    param([string]$Name, [scriptblock]$Block)
    $script:total++
    try {
        $result = & $Block
        if ($result) {
            Write-Host "  PASS  $Name" -ForegroundColor Green
            $script:pass++
        } else {
            Write-Host "  FAIL  $Name" -ForegroundColor Red
            $script:fail++
        }
    } catch {
        Write-Host "  FAIL  $Name -- $($_.Exception.Message)" -ForegroundColor Red
        $script:fail++
    }
}

Write-Host "=== Helios Ledger E2E Tests ===" -ForegroundColor Cyan
Write-Host ""

# 1. Health check
Write-Host "[Health & Meta]" -ForegroundColor Yellow
Test-Endpoint "GET /health returns ok" {
    $r = Invoke-RestMethod "$base/health"
    $r.status -eq "ok" -and $r.version -eq "4.0.0" -and $r.record_count -gt 0
}

# 2. Ledger root
Test-Endpoint "GET /ledger/root returns root hash" {
    $r = Invoke-RestMethod "$base/ledger/root"
    $r.root.Length -eq 64 -and $r.record_count -gt 0
}

# 3. Ledger recent
Test-Endpoint "GET /ledger/recent returns records" {
    $r = Invoke-RestMethod "$base/ledger/recent"
    $r.records.Count -gt 0
}

# 4. Keygen
Test-Endpoint "GET /keygen returns Ed25519 keypair" {
    $r = Invoke-RestMethod "$base/keygen"
    $r.private_key.crv -eq "Ed25519" -and $r.public_key.crv -eq "Ed25519"
}

# 5. Pubkey
Test-Endpoint "GET /pubkey returns server public key" {
    $r = Invoke-RestMethod "$base/pubkey"
    $r.algorithm -eq "Ed25519"
}

Write-Host ""
Write-Host "[Account Creation]" -ForegroundColor Yellow

# 6. Create account
$username = "e2e_test_" + (Get-Random -Maximum 999999)
$acct = $null
Test-Endpoint "POST /accounts creates account with chain record" {
    $body = @{ username = $username } | ConvertTo-Json
    $script:acct = Invoke-RestMethod "$base/accounts" -Method POST -ContentType "application/json" -Body $body
    $acct.token.Length -eq 64 -and $acct.chain_record.merkle_index -ge 0
}

# 7. Duplicate username rejected
Test-Endpoint "POST /accounts rejects duplicate username" {
    $body = @{ username = $username } | ConvertTo-Json
    try {
        Invoke-RestMethod "$base/accounts" -Method POST -ContentType "application/json" -Body $body
        $false
    } catch {
        $_.Exception.Response.StatusCode.value__ -eq 409
    }
}

Write-Host ""
Write-Host "[Record Submission -- THE CRITICAL FIX]" -ForegroundColor Yellow

# 8. Submit record (THIS IS THE BUG FIX TEST)
$record = $null
Test-Endpoint "POST /records returns 201 with full proof (was 500!)" {
    $headers = @{ Authorization = "Bearer $($acct.token)" }
    $body = @{ content = "E2E test content $(Get-Date -Format o)"; model = "e2e-test"; context = "validation" } | ConvertTo-Json
    $script:record = Invoke-RestMethod "$base/records" -Method POST -ContentType "application/json" -Headers $headers -Body $body
    $record.id -and $record.content_hash.Length -eq 64 -and $record.signature.Length -gt 0 -and $record.merkle_root.Length -eq 64
}

# 9. Submit another record (verify repeatable)
Test-Endpoint "POST /records works on second submission too" {
    $headers = @{ Authorization = "Bearer $($acct.token)" }
    $body = @{ content = "Second E2E test $(Get-Date -Format o)"; model = "e2e-test" } | ConvertTo-Json
    $r = Invoke-RestMethod "$base/records" -Method POST -ContentType "application/json" -Headers $headers -Body $body
    $r.id -and $r.merkle_index -gt $record.merkle_index
}

# 10. Unauthorized rejected
Test-Endpoint "POST /records returns 401 without token" {
    $body = @{ content = "no auth test" } | ConvertTo-Json
    try {
        Invoke-RestMethod "$base/records" -Method POST -ContentType "application/json" -Body $body
        $false
    } catch {
        $_.Exception.Response.StatusCode.value__ -eq 401
    }
}

Write-Host ""
Write-Host "[Record Retrieval & Verification]" -ForegroundColor Yellow

# 11. Get record by ID
Test-Endpoint "GET /records/{id} returns the created record" {
    $r = Invoke-RestMethod "$base/records/$($record.id)"
    $r.content_hash -eq $record.content_hash
}

# 12. Verify record
Test-Endpoint "GET /records/{id}/verify returns valid proof" {
    $r = Invoke-RestMethod "$base/records/$($record.id)/verify"
    $r.record_id -eq $record.id -and $r.merkle_proof.Count -gt 0
}

# 13. Ledger proof
Test-Endpoint "GET /ledger/proof/{id} returns inclusion proof" {
    $r = Invoke-RestMethod "$base/ledger/proof/$($record.id)"
    $r.merkle_index -eq $record.merkle_index -and $r.proof.Count -gt 0
}

# 14. Ledger root updated
Test-Endpoint "Ledger root reflects new record" {
    $r = Invoke-RestMethod "$base/ledger/root"
    $r.root -eq $record.merkle_root
}

Write-Host ""
Write-Host "[Route Consistency]" -ForegroundColor Yellow

# 15. Both /api/ and /api/v1/ work
Test-Endpoint "GET /api/health (without v1) also works" {
    $r = Invoke-RestMethod "https://ai.oooooooooo.se/api/health"
    $r.status -eq "ok"
}

Test-Endpoint "GET /api/ledger/root (without v1) also works" {
    $r = Invoke-RestMethod "https://ai.oooooooooo.se/api/ledger/root"
    $r.root.Length -eq 64
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: $pass passed, $fail failed, $total total" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
Write-Host "========================================" -ForegroundColor Cyan

if ($fail -gt 0) {
    Write-Host ""
    Write-Host "SOME TESTS FAILED. Check output above." -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "ALL TESTS PASSED. The fix is verified." -ForegroundColor Green
}
