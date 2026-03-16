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
