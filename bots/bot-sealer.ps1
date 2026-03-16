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
