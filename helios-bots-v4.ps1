# helios-bots.ps1 -- 5 parallel bots stress-testing the Helios Ledger
# Self-contained: creates bots\ folder and all scripts automatically
# Ctrl+C to stop. Run from C:\Users\fogen\HELIOS

Set-Location "C:\Users\fogen\HELIOS"

# Clean up any loose bot files from previous attempts
$junk = @("bot-sealer.ps1","bot-sealer (1).ps1","bot-verifier.ps1","bot-auditor.ps1","bot-loadtest.ps1","bot-security.ps1","helios-bots.ps1","helios-bots-v2.ps1","helios-bots-v3.ps1","files.zip")
foreach ($f in $junk) { if (Test-Path $f) { Remove-Item $f -Force } }

$API = "https://ai.oooooooooo.se/api/v1"

Write-Host ""
Write-Host "  =======================================" -ForegroundColor Cyan
Write-Host "   HELIOS LEDGER  5-BOT STRESS TEST" -ForegroundColor Cyan
Write-Host "  =======================================" -ForegroundColor Cyan
Write-Host ""

# ── Auto-create bot scripts ─────────────────────────────────────────────

New-Item -ItemType Directory -Force -Path bots | Out-Null

# BOT 1: SEALER
@'
param([string]$API, [string]$Token)
$headers = @{ Authorization = "Bearer $Token" }
$models = @("gpt-4o","claude-sonnet-4","gemini-2.5-pro","llama-3.3-70b","mistral-large","deepseek-r1","command-r-plus")
$contexts = @("blog-draft","code-review","legal-summary","medical-note","financial-report","research-abstract","marketing-copy","support-ticket","contract-clause","policy-document")
$cycle = 0
while ($true) {
    $cycle++
    try {
        $n1 = Get-Random -Minimum 2 -Maximum 95
        $n2 = Get-Random -Minimum 1 -Maximum 50
        $ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        $picks = @(
            "Quarterly earnings show $n1 pct revenue increase driven by transformer optimization in the Asia-Pacific segment. Sealed $ts",
            "Patient presents with $n1 symptoms consistent with differential classification. Recommended follow-up in $n2 weeks. Sealed $ts",
            "WHEREAS the parties agree to federated inference binding under European jurisdiction. Contract ref $n1-$n2. Sealed $ts",
            "Abstract: Novel approach to adversarial generation using recursive architecture achieving $n1 pct improvement over baseline. Sealed $ts",
            "Security Advisory CVE-2026-$n1 affects distributed alignment versions prior to $n2. CVSS score 8.$n2. Sealed $ts",
            "AI model summary: Key findings indicate stochastic embedding significantly correlates with reinforcement regularization. Sealed $ts",
            "Market analysis for fintech sector: Current sentiment is bullish. Key risk factors include regulatory changes Q3 $n1. Sealed $ts",
            "Code review PR ${n1} - The tokenization implementation has $n2 potential issues. Recommend refactoring. Sealed $ts",
            "Translation confirmed: Delegation states quantum compression negotiations resume following the summit round $n1. Sealed $ts",
            "Educational content lesson $n1 covers neural distillation. Students should understand $n2 prerequisites. Sealed $ts"
        )
        $content = $picks[(Get-Random -Maximum $picks.Count)]
        $model = $models[(Get-Random -Maximum $models.Count)]
        $ctx = $contexts[(Get-Random -Maximum $contexts.Count)]
        $body = @{ content = $content; model = $model; context = $ctx } | ConvertTo-Json
        $r = Invoke-RestMethod "$API/records" -Method POST -ContentType "application/json" -Headers $headers -Body $body
        Write-Output "[SEALER #$cycle] idx=$($r.merkle_index) model=$model ctx=$ctx hash=$($r.content_hash.Substring(0,12))..."
    } catch {
        Write-Output "[SEALER #$cycle] ERROR: $($_.Exception.Message)"
    }
    Start-Sleep -Milliseconds (Get-Random -Minimum 2000 -Maximum 5000)
}
'@ | Set-Content "bots\bot-sealer.ps1" -Encoding UTF8

# BOT 2: VERIFIER
@'
param([string]$API, [string]$Token)
$cycle = 0
while ($true) {
    $cycle++
    try {
        $recent = Invoke-RestMethod "$API/ledger/recent"
        if ($recent.records.Count -eq 0) { Write-Output "[VERIFY #$cycle] No records yet..."; Start-Sleep 5; continue }
        $pick = $recent.records[(Get-Random -Maximum $recent.records.Count)]
        $v = Invoke-RestMethod "$API/records/$($pick.id)/verify"
        $raw = Invoke-RestMethod "$API/records/$($pick.id)"
        $hashOk = $raw.content_hash -eq $v.content_hash
        $sigOk = $raw.signature -eq $v.signature
        $proofOk = $v.merkle_proof.Count -gt 0
        if ($v.valid -and $proofOk -and $hashOk -and $sigOk) {
            Write-Output "[VERIFY #$cycle] VALID idx=$($raw.merkle_index) depth=$($v.proof_depth) model=$($raw.model)"
        } else {
            Write-Output "[VERIFY #$cycle] ANOMALY! valid=$($v.valid) proof=$proofOk hash=$hashOk sig=$sigOk id=$($pick.id)"
        }
    } catch {
        Write-Output "[VERIFY #$cycle] ERROR: $($_.Exception.Message)"
    }
    Start-Sleep -Milliseconds (Get-Random -Minimum 3000 -Maximum 6000)
}
'@ | Set-Content "bots\bot-verifier.ps1" -Encoding UTF8

# BOT 3: AUDITOR
@'
param([string]$API, [string]$Token)
$cycle = 0; $lastRoot = $null; $lastCount = 0; $rootChanges = 0; $anomalies = 0
while ($true) {
    $cycle++
    try {
        $health = Invoke-RestMethod "$API/health"
        $ledger = Invoke-RestMethod "$API/ledger/root"
        if ($lastRoot -and $ledger.root -ne $lastRoot) { $rootChanges++ }
        if ($lastCount -gt 0 -and $ledger.record_count -lt $lastCount) { $anomalies++ }
        $proofStatus = "skip"
        $recent = Invoke-RestMethod "$API/ledger/recent"
        if ($recent.records.Count -gt 0) {
            $proof = Invoke-RestMethod "$API/ledger/proof/$($recent.records[0].id)"
            if ($proof.merkle_root -eq $ledger.root) { $proofStatus = "consistent" } else { $proofStatus = "DRIFT"; $anomalies++ }
        }
        Write-Output "[AUDIT #$cycle] health=$($health.status) count=$($ledger.record_count) root_changes=$rootChanges proof=$proofStatus anomalies=$anomalies"
        $lastRoot = $ledger.root; $lastCount = $ledger.record_count
    } catch {
        Write-Output "[AUDIT #$cycle] ERROR: $($_.Exception.Message)"; $anomalies++
    }
    Start-Sleep -Milliseconds (Get-Random -Minimum 4000 -Maximum 8000)
}
'@ | Set-Content "bots\bot-auditor.ps1" -Encoding UTF8

# BOT 4: LOAD TESTER
@'
param([string]$API, [string]$Token)
$headers = @{ Authorization = "Bearer $Token" }
$cycle = 0; $successes = 0; $failures = 0; $totalMs = 0; $burstSize = 3
while ($true) {
    $cycle++
    $burstStart = Get-Date
    for ($i = 1; $i -le $burstSize; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $ts = Get-Date -Format o; $rnd = Get-Random
            $body = @{ content = "loadtest burst=$cycle seq=$i t=$ts r=$rnd"; model = "loadtest-bot"; context = "throughput" } | ConvertTo-Json
            $null = Invoke-RestMethod "$API/records" -Method POST -ContentType "application/json" -Headers $headers -Body $body
            $sw.Stop(); $successes++; $totalMs += $sw.ElapsedMilliseconds
        } catch { $sw.Stop(); $failures++ }
    }
    $burstMs = ((Get-Date) - $burstStart).TotalMilliseconds
    $avgMs = if ($successes -gt 0) { [math]::Round($totalMs / $successes) } else { 0 }
    $rps = if ($burstMs -gt 0) { [math]::Round(($burstSize / $burstMs) * 1000, 1) } else { 0 }
    Write-Output "[LOAD  #$cycle] burst=$burstSize in $([math]::Round($burstMs))ms ($rps req/s) ok=$successes fail=$failures avg=${avgMs}ms"
    Start-Sleep -Milliseconds (Get-Random -Minimum 5000 -Maximum 8000)
}
'@ | Set-Content "bots\bot-loadtest.ps1" -Encoding UTF8

# BOT 5: SECURITY PROBE
@'
param([string]$API, [string]$Token)
$headers = @{ Authorization = "Bearer $Token" }
$passed = 0; $failed = 0; $round = 0
function Probe([string]$Name, [scriptblock]$Test, [int]$Expect) {
    try {
        & $Test
        if ($Expect -eq 0) { $script:passed++; Write-Output "[SECUR] PASS  $Name" }
        else { $script:failed++; Write-Output "[SECUR] FAIL  $Name (expected $Expect got success)" }
    } catch {
        $s = 0; if ($_.Exception.Response) { $s = [int]$_.Exception.Response.StatusCode }
        if ($Expect -gt 0 -and $s -eq $Expect) { $script:passed++; Write-Output "[SECUR] PASS  $Name ($s)" }
        elseif ($Expect -gt 0) { $script:failed++; Write-Output "[SECUR] FAIL  $Name (want $Expect got $s)" }
        else { $script:failed++; Write-Output "[SECUR] FAIL  $Name ($($_.Exception.Message))" }
    }
}
while ($true) {
    $round++
    Probe "No auth" { Invoke-RestMethod "$API/records" -Method POST -ContentType "application/json" -Body '{"content":"x"}' } 401
    Probe "Bad token" { $b=@{Authorization="Bearer 0000000000000000000000000000000000000000000000000000000000000000"}; Invoke-RestMethod "$API/records" -Method POST -ContentType "application/json" -Headers $b -Body '{"content":"x"}' } 401
    Probe "Empty bearer" { $b=@{Authorization="Bearer "}; Invoke-RestMethod "$API/records" -Method POST -ContentType "application/json" -Headers $b -Body '{"content":"x"}' } 401
    Start-Sleep -Milliseconds 500
    Probe "Empty content" { Invoke-RestMethod "$API/records" -Method POST -ContentType "application/json" -Headers $headers -Body '{"content":""}' } 400
    Probe "No content field" { Invoke-RestMethod "$API/records" -Method POST -ContentType "application/json" -Headers $headers -Body '{"model":"x"}' } 400
    Probe "Bad JSON" { Invoke-RestMethod "$API/records" -Method POST -ContentType "application/json" -Headers $headers -Body 'broken{{{' } 400
    Start-Sleep -Milliseconds 500
    Probe "Short username" { Invoke-RestMethod "$API/accounts" -Method POST -ContentType "application/json" -Body '{"username":"ab"}' } 400
    Probe "XSS username" { Invoke-RestMethod "$API/accounts" -Method POST -ContentType "application/json" -Body '{"username":"<script>"}' } 400
    Probe "404 record" { Invoke-RestMethod "$API/records/00000000-0000-0000-0000-000000000000" } 404
    Probe "404 verify" { Invoke-RestMethod "$API/records/00000000-0000-0000-0000-000000000000/verify" } 404
    Start-Sleep -Milliseconds 500
    Probe "Valid submit" {
        $ts = Get-Date -Format o
        $body = @{content="canary $ts";model="security-bot"} | ConvertTo-Json
        $r = Invoke-RestMethod "$API/records" -Method POST -ContentType "application/json" -Headers $headers -Body $body
        if (-not $r.id) { throw "no id" }
    } 0
    Write-Output "[SECUR ----] Round $round done: $passed passed, $failed failed"
    Start-Sleep -Milliseconds (Get-Random -Minimum 10000 -Maximum 18000)
}
'@ | Set-Content "bots\bot-security.ps1" -Encoding UTF8

Write-Host "  [ok] Bot scripts created in bots\" -ForegroundColor Green

# ── Create bot accounts ─────────────────────────────────────────────────

$botNames = @("sealer","verifier","auditor","loadtest","security")
$tokens = @{}

Write-Host "  [..] Creating 5 bot accounts..." -ForegroundColor Yellow
foreach ($name in $botNames) {
    $user = "bot_${name}_" + (Get-Random -Maximum 99999)
    $body = @{ username = $user } | ConvertTo-Json
    try {
        $acct = Invoke-RestMethod "$API/accounts" -Method POST -ContentType "application/json" -Body $body
        $tokens[$name] = $acct.token
        Write-Host "       $name -> $user (chain idx $($acct.chain_record.merkle_index))" -ForegroundColor DarkGray
    } catch {
        Write-Host "  [FAIL] ${name}: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
Write-Host "  [ok] All accounts created" -ForegroundColor Green
Write-Host ""

# ── Launch bots ─────────────────────────────────────────────────────────

$jobs = @{}
foreach ($name in $botNames) {
    $script = Join-Path (Resolve-Path bots) "bot-$name.ps1"
    $job = Start-Job -FilePath $script -ArgumentList $API, $tokens[$name] -Name $name
    $jobs[$name] = $job
    Write-Host "  [*] $($name.ToUpper()) started (job $($job.Id))" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "  All 5 bots running. Ctrl+C to stop." -ForegroundColor Green
Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# ── Stream output ───────────────────────────────────────────────────────

$colorMap = @{ "SEALER"="Cyan"; "VERIFY"="Green"; "AUDIT"="Yellow"; "LOAD"="Magenta"; "SECUR"="Red" }

try {
    while ($true) {
        foreach ($name in $botNames) {
            $job = $jobs[$name]
            $lines = Receive-Job -Job $job -ErrorAction SilentlyContinue
            if ($lines) {
                foreach ($line in $lines) {
                    $color = "Gray"
                    foreach ($key in $colorMap.Keys) { if ($line -match $key) { $color = $colorMap[$key]; break } }
                    if ($line -match "ERROR|FAIL|ANOMALY|DRIFT") {
                        Write-Host $line -ForegroundColor White -BackgroundColor DarkRed
                    } else {
                        Write-Host $line -ForegroundColor $color
                    }
                }
            }
            if ($job.State -eq "Completed" -or $job.State -eq "Failed") {
                Write-Host "  [!] $($name.ToUpper()) died, restarting..." -ForegroundColor White -BackgroundColor DarkYellow
                Remove-Job -Job $job -Force
                $script = Join-Path (Resolve-Path bots) "bot-$name.ps1"
                $newJob = Start-Job -FilePath $script -ArgumentList $API, $tokens[$name] -Name $name
                $jobs[$name] = $newJob
            }
        }
        Start-Sleep -Milliseconds 400
    }
} finally {
    Write-Host ""
    Write-Host "  Shutting down..." -ForegroundColor Yellow
    foreach ($name in $botNames) {
        Stop-Job -Job $jobs[$name] -ErrorAction SilentlyContinue
        Remove-Job -Job $jobs[$name] -Force -ErrorAction SilentlyContinue
    }
    try {
        $h = Invoke-RestMethod "$API/health"
        Write-Host ""
        Write-Host "  =======================================" -ForegroundColor Cyan
        Write-Host "   FINAL: $($h.record_count) records on chain (v$($h.version))" -ForegroundColor Cyan
        Write-Host "  =======================================" -ForegroundColor Cyan
    } catch {}
}
