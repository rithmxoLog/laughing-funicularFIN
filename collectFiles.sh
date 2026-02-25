# collect-md-sh.ps1
# Searches all folders/subfolders for .md, .sh, and .txt files and consolidates their content into a single .txt file

$outputFile = Join-Path $PSScriptRoot "collected_files.txt"

# Clear or create the output file
"" | Out-File -FilePath $outputFile -Encoding UTF8

# Get all .md, .sh, and .txt files recursively from C:\
$files = Get-ChildItem -Path "C:\" -Recurse -Include *.md, *.sh, *.txt -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -ne $outputFile }

foreach ($file in $files) {
    $separator = "=" * 80
    $header = @"
$separator
FILE: $($file.Name)
PATH: $($file.FullName)
$separator
"@
    Add-Content -Path $outputFile -Value $header -Encoding UTF8
    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        Add-Content -Path $outputFile -Value $content -Encoding UTF8
    } catch {
        Add-Content -Path $outputFile -Value "[ERROR: Could not read file - $($_.Exception.Message)]" -Encoding UTF8
    }
    Add-Content -Path $outputFile -Value "`n`n" -Encoding UTF8
}

Write-Host "Done! Found $($files.Count) files. Output saved to $outputFile"
Read-Host "Press Enter to exit"