# Obsidian MD to PDF Batch Export Script
# Usage: Right-click this file and select "Run with PowerShell"

param(
    [string]$VaultPath = "e:\计算机组成原理\Computer-Organization-Notes",
    [string]$OutputPath = "e:\Computer-Organization-Notes\PDF_Output"
)

if (!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

$markdownFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse | Where-Object { $_.FullName -notmatch "\\\.obsidian\\|\-assets\\|node_modules" }

$total = $markdownFiles.Count
$current = 0

Write-Host "Found $total MD files" -ForegroundColor Cyan
Write-Host ""

foreach ($file in $markdownFiles) {
    $current++
    $relativePath = $file.FullName.Replace($VaultPath, "").TrimStart("\")
    Write-Host "[$current/$total] Processing: $relativePath"

    try {
        $pdfFileName = $file.BaseName + ".pdf"
        $pdfFullPath = Join-Path $OutputPath $pdfFileName

        $htmlContent = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $htmlContent = $htmlContent -replace '!\[\[(.*?)\]\]', '<img src="$1" />'
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
body { font-family: 'Microsoft YaHei', sans-serif; padding: 20px; }
h1, h2, h3, h4, h5, h6 { margin-top: 1.5em; }
img { max-width: 100%; height: auto; }
code { background: #f5f5f5; padding: 2px 6px; border-radius: 3px; }
pre { background: #f5f5f5; padding: 10px; overflow-x: auto; border-radius: 5px; }
</style>
</head>
<body>
$htmlContent
</body>
</html>
"@

        $tempHtml = Join-Path $env:TEMP "temp_$([System.Guid]::NewGuid().ToString('N')).html"
        $htmlContent | Out-File -FilePath $tempHtml -Encoding UTF8

        $edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
        if (!(Test-Path $edgePath)) {
            $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
        }

        $args = @(
            "--headless",
            "--disable-gpu",
            "--print-to-pdf=`"$pdfFullPath`"",
            "--no-pdf-header-footer",
            "`"$tempHtml`""
        )

        Start-Process -FilePath $edgePath -ArgumentList $args -Wait -NoNewWindow

        if (Test-Path $tempHtml) {
            Remove-Item $tempHtml -Force
        }

        if (Test-Path $pdfFullPath) {
            Write-Host "  -> Saved: $pdfFileName" -ForegroundColor Green
        } else {
            Write-Host "  -> Warning: PDF not generated" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  -> Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Export completed!" -ForegroundColor Green
Write-Host "PDF files saved to: $OutputPath" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Read-Host "Press Enter to exit"