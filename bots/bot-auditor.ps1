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
