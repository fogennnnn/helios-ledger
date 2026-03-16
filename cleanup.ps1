# cleanup.ps1 -- Clean up the HELIOS folder
# Moves all old scripts/files to _archive, keeps only production files
# Run from C:\Users\fogen\HELIOS

Set-Location "C:\Users\fogen\HELIOS"

Write-Host "=== HELIOS Folder Cleanup ===" -ForegroundColor Cyan
Write-Host ""

# Create archive folder
$archive = "_archive"
New-Item -ItemType Directory -Force -Path $archive | Out-Null
Write-Host "Created $archive\" -ForegroundColor Gray

# Files to KEEP in HELIOS root (only what matters for production)
$keepRoot = @(
    "docs",
    "helios-worker",
    ".git",
    ".github",
    ".gitignore",
    "README.md",
    "LICENSE",
    "cleanup.ps1",
    "_archive"
)

# Files to KEEP in helios-worker (only current production)
$keepWorker = @(
    "worker.js",
    "worker-v4.js",
    "wrangler.toml",
    "keygen.js",
    "package.json",
    "package-lock.json",
    "node_modules",
    ".wrangler"
)

# Step 1: Archive loose files in HELIOS root
Write-Host ""
Write-Host "[1/3] Archiving old root files..." -ForegroundColor Yellow
$moved = 0
Get-ChildItem -Path . -File | ForEach-Object {
    if ($keepRoot -notcontains $_.Name) {
        Move-Item -Path $_.FullName -Destination "$archive\$($_.Name)" -Force
        Write-Host "  -> $($_.Name)" -ForegroundColor DarkGray
        $moved++
    }
}
Write-Host "  Archived $moved files from root" -ForegroundColor Green

# Step 2: Archive old worker files
Write-Host ""
Write-Host "[2/3] Archiving old worker files..." -ForegroundColor Yellow
$movedW = 0
if (Test-Path "helios-worker") {
    Get-ChildItem -Path "helios-worker" -File | ForEach-Object {
        if ($keepWorker -notcontains $_.Name) {
            $dest = "$archive\worker_$($_.Name)"
            Move-Item -Path $_.FullName -Destination $dest -Force
            Write-Host "  -> helios-worker\$($_.Name)" -ForegroundColor DarkGray
            $movedW++
        }
    }
}
Write-Host "  Archived $movedW files from helios-worker\" -ForegroundColor Green

# Step 3: Show what's left
Write-Host ""
Write-Host "[3/3] Clean state:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  HELIOS\" -ForegroundColor White
Get-ChildItem -Path . -Exclude ".git" | ForEach-Object {
    $icon = if ($_.PSIsContainer) { "[dir]" } else { "     " }
    Write-Host "    $icon $($_.Name)" -ForegroundColor $(if ($_.PSIsContainer) { "Cyan" } else { "Gray" })
}
Write-Host ""
Write-Host "  HELIOS\helios-worker\" -ForegroundColor White
if (Test-Path "helios-worker") {
    Get-ChildItem -Path "helios-worker" -Exclude "node_modules",".wrangler" | ForEach-Object {
        $icon = if ($_.PSIsContainer) { "[dir]" } else { "     " }
        Write-Host "    $icon $($_.Name)" -ForegroundColor $(if ($_.PSIsContainer) { "Cyan" } else { "Gray" })
    }
}

Write-Host ""
$totalArchived = $moved + $movedW
Write-Host "Done! $totalArchived files archived to _archive\" -ForegroundColor Green
Write-Host "Delete _archive\ anytime once you are sure nothing is needed." -ForegroundColor Gray
