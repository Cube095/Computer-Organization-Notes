# Obsidian MD to PDF 批量导出脚本
# 使用方法：右键点击此脚本，选择"使用 PowerShell 运行"

param(
    [string]$VaultPath = "e:\计算机组成原理\Computer-Organization-Notes",
    [string]$OutputPath = "e:\计算机组成原理\Computer-Organization-Notes\PDF输出"
)

if (!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

$markdownFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse | Where-Object { $_.FullName -notmatch "\\\.obsidian\\|\-assets\\|node_modules" }

$total = $markdownFiles.Count
$current = 0

Write-Host "找到 $total 个 MD 文件" -ForegroundColor Cyan
Write-Host ""

foreach ($file in $markdownFiles) {
    $current++
    $relativePath = $file.FullName.Replace($VaultPath, "").TrimStart("\")
    Write-Host "[$current/$total] 处理中: $relativePath"

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
            Write-Host "  -> 已保存: $pdfFileName" -ForegroundColor Green
        } else {
            Write-Host "  -> 警告: PDF 文件未生成" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  -> 错误: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "导出完成！" -ForegroundColor Green
Write-Host "PDF 文件保存在: $OutputPath" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Read-Host "按 Enter 键退出"