# collect-md-sh.ps1
# Searches all folders/subfolders for .md and .sh files and consolidates their content into a single .txt file

$outputFile = Join-Path $PSScriptRoot "collected_files.txt"

# Clear or create the output file
"" | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host ""
Write-Host "  Scanning C:\ for .md and .sh files..." -ForegroundColor Cyan
Write-Host "  Please wait, this may take a while..." -ForegroundColor DarkGray
Write-Host ""

# Get all .md and .sh files recursively from C:\
$files = Get-ChildItem -Path "C:\" -Recurse -Include *.md, *.sh -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -ne $outputFile }

$totalFiles = $files.Count
$current = 0
$errors = 0
$startTime = Get-Date

Write-Host "  Found $totalFiles files. Processing..." -ForegroundColor Green
Write-Host ""

foreach ($file in $files) {
    $current++
    $percent = [math]::Round(($current / $totalFiles) * 100)

    # Progress bar
    $barLength = 30
    $filled = [math]::Round($barLength * $current / $totalFiles)
    $empty = $barLength - $filled
    $bar = "[" + ("█" * $filled) + ("░" * $empty) + "]"

    Write-Host "`r  $bar $percent% ($current/$totalFiles) " -NoNewline -ForegroundColor Yellow
    Write-Host "Processing: $($file.Name)".PadRight(60) -NoNewline -ForegroundColor White

    $separator = "=" * 80
    $header = "$separator`nFILE: $($file.Name)`nPATH: $($file.FullName)`n$separator"

    Add-Content -Path $outputFile -Value $header -Encoding UTF8

    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        Add-Content -Path $outputFile -Value $content -Encoding UTF8
    } catch {
        $errors++
        Add-Content -Path $outputFile -Value "[ERROR: Could not read file - $($_.Exception.Message)]" -Encoding UTF8
    }

    Add-Content -Path $outputFile -Value "`n`n" -Encoding UTF8
}

$elapsed = (Get-Date) - $startTime

# Final summary
Write-Host ""
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Green
Write-Host "  COMPLETED" -ForegroundColor Green
Write-Host "  ============================================" -ForegroundColor Green
Write-Host "    Files processed : $totalFiles" -ForegroundColor White
Write-Host "    Errors          : $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "White" })
Write-Host "    Time elapsed    : $($elapsed.ToString('mm\:ss'))" -ForegroundColor White
Write-Host "    Output saved to : $outputFile" -ForegroundColor White
Write-Host "  ============================================" -ForegroundColor Green
Write-Host ""

Read-Host "  Press Enter to exit"