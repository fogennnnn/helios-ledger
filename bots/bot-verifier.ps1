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
