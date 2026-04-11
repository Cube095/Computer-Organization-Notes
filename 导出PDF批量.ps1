# Obsidian MD to PDF 批量导出脚本
# 使用方法：右键点击此脚本，选择"使用 PowerShell 运行"

$vaultPath = "e:\计算机组成原理\Computer-Organization-Notes"
$outputPath = Join-Path $vaultPath "PDF输出"
$markdownFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse | Where-Object { $_.FullName -notmatch "\\\.obsidian\\" }

if (!(Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

Add-Type -AssemblyName System.Windows.Forms

$total = $markdownFiles.Count
$current = 0

foreach ($file in $markdownFiles) {
    $current++
    $relativePath = $file.FullName.Replace($vaultPath, "").TrimStart("\")
    Write-Host "[$current/$total] 正在处理: $relativePath"

    try {
        $pdfFileName = ($file.BaseName + ".pdf")
        $pdfFullPath = Join-Path $outputPath $pdfFileName

        $ie = New-Object -ComObject InternetExplorer.Application
        $ie.Visible = $false
        $ie.Navigate($file.FullName)

        while ($ie.Busy -or $ie.ReadyState -ne 4) {
            Start-Sleep -Milliseconds 100
        }

        $ie.ExecWB(6, 2)

        Start-Sleep -Seconds 2

        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ie) | Out-Null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()

        Write-Host "  -> 完成: $pdfFileName"
    }
    catch {
        Write-Host "  -> 失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "所有文件处理完成！" -ForegroundColor Green
Write-Host "PDF 文件保存在: $outputPath"
Start-Sleep -Seconds 3