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
