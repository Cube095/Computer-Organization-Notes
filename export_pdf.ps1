# Obsidian MD to PDF Batch Export Script

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $scriptDir
$VLT = Get-Location
$OUT = "$env:USERPROFILE\Desktop\PDF_Output"

if (!(Test-Path -LiteralPath $OUT)) {
    New-Item -ItemType Directory -Path $OUT | Out-Null
}

$files = Get-ChildItem -Filter "*.md" -Recurse | Where-Object { $_.FullName -notmatch "\.obsidian|\-assets|node_modules" }

$total = $files.Count
$current = 0

Write-Host "Found $total MD files" -ForegroundColor Cyan
Write-Host ""

foreach ($f in $files) {
    $current++
    $rel = $f.FullName.Substring($VLT.Path.Length).TrimStart("\")
    Write-Host "[$current/$total] Processing: $rel"

    try {
        $pdfName = $f.BaseName + ".pdf"
        $pdfPath = Join-Path $OUT $pdfName

        $html = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
        $html = $html -replace '!\[\[(.*?)\]\]', '<img src="$1" />'
        $html = @"
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
$html
</body>
</html>
"@

        $tmp = Join-Path $env:TEMP "t_$([System.Guid]::NewGuid().ToString('N')).html"
        $html | Out-File -FilePath $tmp -Encoding UTF8

        $edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

        $argList = @(
            "--headless",
            "--disable-gpu",
            "--print-to-pdf=`"$pdfPath`"",
            "--no-pdf-header-footer",
            "`"$tmp`""
        )

        Start-Process -FilePath $edge -ArgumentList $argList -Wait -NoNewWindow

        if (Test-Path $tmp) { Remove-Item $tmp -Force }

        if (Test-Path $pdfPath) {
            Write-Host "  -> Saved: $pdfName" -ForegroundColor Green
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
Write-Host "PDF files saved to: $OUT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan