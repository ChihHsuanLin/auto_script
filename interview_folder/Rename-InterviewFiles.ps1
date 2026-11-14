# ==============================
# Interview Files Batch Renamer
# ==============================

$Folder = (Get-Location).Path
$FolderName = Split-Path $Folder -Leaf
$OldFolder = Join-Path $Folder "old"
$LogFile = Join-Path $Folder "rename_log.csv"

# ==============================
# File Type Settings
# ==============================

$WordExts  = @(".doc", ".docx")
$PdfExts   = @(".pdf")
$ImageExts = @(".jpg", ".jpeg", ".png", ".bmp", ".gif", ".webp")
$TxtExts   = @(".txt")
$MdExts    = @(".md")

# ==============================
# Rule Keywords
# 之後要新增關鍵字，主要改這裡
# ==============================

$Rule1Keywords  = @("CESBG人員基本資料表")
$Rule2Keywords  = @("自傳")
$Rule3Keywords  = @("Resume", "推薦", "CV")
$Rule4Keywords  = @("畢業證書", "證書", "成績單", "排名", "排行", "證件", "證明", "成績", "退伍", "證照")
$Rule5Keywords  = @("測評報告")
$Rule6Keywords  = @("試題", "考題", "題目")
$Rule7Keywords  = @("答案", "答題", "答卷")
$Rule8Keywords  = @("論文", "專題", "摘要")
$Rule9Keywords  = @("Q&A")
$Rule10Keywords = @("反饋", "Amy", "Rebecca", "Ma", "KK")
$Rule11Keywords = @("mm", "逐字稿")

# ==============================
# Helper Functions
# ==============================

function Contains-AnyKeyword {
    param (
        [string]$Text,
        [string[]]$Keywords
    )

    foreach ($keyword in $Keywords) {
        if ($Text -like "*$keyword*") {
            return $true
        }
    }
    return $false
}

function Get-CandidateName {
    param ([string]$FolderName)

    $parts = $FolderName -split "[-_]"
    return $parts[$parts.Count - 1]
}

function Clean-Text {
    param ([string]$Text)

    $cleaned = $Text
    $cleaned = $cleaned -replace "[\s\-_]+", "_"
    $cleaned = $cleaned.Trim("_")
    return $cleaned
}

function Remove-CandidateName {
    param (
        [string]$Text,
        [string]$CandidateName
    )

    $result = $Text -replace [regex]::Escape($CandidateName), ""
    $result = Clean-Text $result
    return $result
}

function Get-UniqueName {
    param (
        [string]$Folder,
        [string]$BaseName,
        [string]$Ext
    )

    $target = Join-Path $Folder "$BaseName$Ext"

    if (-not (Test-Path $target)) {
        return "$BaseName$Ext"
    }

    $i = 1
    while ($true) {
        $serial = "{0:D2}" -f $i
        $newName = "${BaseName}_${serial}${Ext}"
        $target = Join-Path $Folder $newName

        if (-not (Test-Path $target)) {
            return $newName
        }

        $i++
    }
}

function Get-InterviewerName {
    param ([string]$FileName)

    if ($FileName -like "*Amy*") { return "Amy" }
    if ($FileName -like "*Rebecca*") { return "Rebecca" }
    if ($FileName -like "*Ma*") { return "Ma" }
    if ($FileName -like "*KK*") { return "KK" }

    return ""
}

function Get-PositionFromAssessmentFile {
    param (
        [string]$BaseName,
        [string]$CandidateName
    )

    $text = $BaseName
    $text = $text -replace "測評報告", ""
    $text = $text -replace [regex]::Escape($CandidateName), ""
    $text = Clean-Text $text

    if ([string]::IsNullOrWhiteSpace($text)) {
        return "職位未辨識"
    }

    return $text
}

function Test-IsInterviewScreenshot {
    param ([System.IO.FileInfo]$File)

    $ext = $File.Extension.ToLower()

    if ($ImageExts -notcontains $ext) {
        return $false
    }

    # Rule 4 / Rule 7 會先吃掉部分圖片，不算面試截圖
    if (Contains-AnyKeyword $File.Name $Rule4Keywords) {
        return $false
    }

    if (Contains-AnyKeyword $File.Name $Rule7Keywords) {
        return $false
    }

    return $true
}

function Get-NewFileName {
    param (
        [System.IO.FileInfo]$File,
        [string]$CandidateName,
        [string]$RecommendSource,
        [hashtable]$ScreenshotSerialMap
    )

    $oldName = $File.Name
    $baseName = $File.BaseName
    $ext = $File.Extension.ToLower()

    # Rule 1: CESBG人員基本資料表 / Word or PDF
    if ((Contains-AnyKeyword $oldName $Rule1Keywords) -and (($WordExts + $PdfExts) -contains $ext)) {
        return "01_${CandidateName}_CESBG人員基本資料表$ext"
    }

    # Rule 2: 自傳 / Word or PDF
    if ((Contains-AnyKeyword $oldName $Rule2Keywords) -and (($WordExts + $PdfExts) -contains $ext)) {
        return "02_${CandidateName}_中文自傳$ext"
    }

    # Rule 3: Resume / 推薦 / CV / Word or PDF
    if ((Contains-AnyKeyword $oldName $Rule3Keywords) -and (($WordExts + $PdfExts) -contains $ext)) {
        return "01_${CandidateName}_CV_${RecommendSource}推薦$ext"
    }

    # Rule 4: 證書 / 成績單 / 證件 / Word or PDF or Image
    if ((Contains-AnyKeyword $oldName $Rule4Keywords) -and (($WordExts + $PdfExts + $ImageExts) -contains $ext)) {
        $label = Remove-CandidateName $baseName $CandidateName

        if ([string]::IsNullOrWhiteSpace($label)) {
            $label = $baseName
        }

        return "03_${CandidateName}_${label}$ext"
    }

    # Rule 5: 測評報告 / PDF
    if ((Contains-AnyKeyword $oldName $Rule5Keywords) -and ($PdfExts -contains $ext)) {
        $position = Get-PositionFromAssessmentFile $baseName $CandidateName
        return "04_${CandidateName}_${position}_測評報告$ext"
    }

    # Rule 6: 試題 / 考題 / 題目 / Word or PDF
    if ((Contains-AnyKeyword $oldName $Rule6Keywords) -and (($WordExts + $PdfExts) -contains $ext)) {
        return "05_${CandidateName}_筆試考卷$ext"
    }

    # Rule 7: 答案 / 答題 / 答卷 / Word or PDF or Image or TXT or MD
    if ((Contains-AnyKeyword $oldName $Rule7Keywords) -and (($WordExts + $PdfExts + $ImageExts + $TxtExts + $MdExts) -contains $ext)) {
        return "05_${CandidateName}_筆試答卷$ext"
    }

    # Rule 8: 論文 / Word or PDF
    if ((Contains-AnyKeyword $oldName $Rule8Keywords) -and (($WordExts + $PdfExts) -contains $ext)) {
        return "06_${CandidateName}_論文主題與中文摘要$ext"
    }

    # Rule 9: Q&A / Word or PDF
    if ((Contains-AnyKeyword $oldName $Rule9Keywords) -and (($WordExts + $PdfExts) -contains $ext)) {
        return "07_${CandidateName}_新幹班Q&A$ext"
    }

    # Rule 10: 面試反饋 / TXT
    if ((Contains-AnyKeyword $oldName $Rule10Keywords) -and ($TxtExts -contains $ext)) {
        $interviewer = Get-InterviewerName $oldName

        if ([string]::IsNullOrWhiteSpace($interviewer)) {
            $interviewer = Read-Host "檔案 [$oldName] 找不到面試官名字，請輸入面試官名字"
        }

        return "08_${CandidateName}_面試反饋_${interviewer}$ext"
    }

    # Rule 11: 面試逐字稿 / TXT
    if ((Contains-AnyKeyword $oldName $Rule11Keywords) -and ($TxtExts -contains $ext)) {
        return "09_${CandidateName}_面試逐字稿$ext"
    }

    # Rule 12: 其他 Image 檔案（依截圖時間編序號）
    if ($ImageExts -contains $ext) {
        $serial = "01"

        if ($null -ne $ScreenshotSerialMap -and $ScreenshotSerialMap.ContainsKey($File.FullName)) {
            $serial = $ScreenshotSerialMap[$File.FullName]
        }

        return "09_${CandidateName}_面試截圖_${serial}$ext"
    }

    return ""
}

# ==============================
# Main Program
# ==============================

Write-Host ""
Write-Host "========== 面試資料批量改名工具 =========="
Write-Host ""
Write-Host "目前資料夾：$Folder"
Write-Host ""
Write-Host "規則摘要："
Write-Host "1. CESBG人員基本資料表 Word / PDF -> 01_姓名_CESBG人員基本資料表"
Write-Host "2. 自傳 Word / PDF -> 02_姓名_中文自傳"
Write-Host "3. Resume / 推薦 / CV -> 01_姓名_CV_xx推薦"
Write-Host "4. 證書 / 成績單 / 證件等 -> 03_姓名_原檔案標示"
Write-Host "5. 測評報告 PDF -> 04_姓名_職位_測評報告"
Write-Host "6. 試題 / 考題 / 題目 -> 05_姓名_筆試考卷"
Write-Host "7. 答案 / 答題 / 答卷 Word / PDF / Image / TXT / MD -> 05_姓名_筆試答卷"
Write-Host "8. 論文 / 專題 / 摘要 -> 06_姓名_論文主題與中文摘要"
Write-Host "9. Q&A -> 07_姓名_新幹班Q&A"
Write-Host "10. 反饋 / Amy / Rebecca / Ma / KK TXT -> 08_姓名_面試反饋_面試官"
Write-Host "11. mm / 逐字稿 TXT -> 09_姓名_面試逐字稿"
Write-Host "12. 其他 Image -> 09_姓名_面試截圖_01（依截圖時間排序）"
Write-Host ""

$CandidateName = Get-CandidateName $FolderName
Write-Host "偵測到候選人姓名：$CandidateName"
Write-Host ""

$RecommendSource = Read-Host "請輸入 Rule 3 的推薦來源，例如 HR、主管、內推、Rebecca"

$Files = Get-ChildItem -Path $Folder -File | Where-Object {
    $_.DirectoryName -ne $OldFolder
}

# Rule 12: 多張截圖依 LastWriteTime 由早到晚編 01、02、03...
$ScreenshotSerialMap = @{}
$ScreenshotFiles = @($Files | Where-Object { Test-IsInterviewScreenshot $_ } | Sort-Object LastWriteTime, Name)
$ScreenshotIndex = 1

foreach ($screenshot in $ScreenshotFiles) {
    $ScreenshotSerialMap[$screenshot.FullName] = "{0:D2}" -f $ScreenshotIndex
    $ScreenshotIndex++
}

$Preview = @()

foreach ($file in $Files) {
    $newName = Get-NewFileName -File $file -CandidateName $CandidateName -RecommendSource $RecommendSource -ScreenshotSerialMap $ScreenshotSerialMap

    if (-not [string]::IsNullOrWhiteSpace($newName)) {
        $newBase = [System.IO.Path]::GetFileNameWithoutExtension($newName)
        $newExt = [System.IO.Path]::GetExtension($newName)
        $newName = Get-UniqueName -Folder $Folder -BaseName $newBase -Ext $newExt
    }

    $Preview += [PSCustomObject]@{
        OldFilename = $file.Name
        NewFilename = $newName
    }
}

Write-Host ""
Write-Host "========== Rename Preview =========="
$PreviewSorted = $Preview | Sort-Object `
    @{ Expression = { [string]::IsNullOrWhiteSpace($_.NewFilename) }; Ascending = $true },
    @{ Expression = { $_.NewFilename }; Ascending = $true }

$PreviewSorted | Format-Table -AutoSize

$confirm = Read-Host "是否確認執行？輸入 Y 繼續，其他任意鍵取消"

if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "已取消。"
    exit
}

if (-not (Test-Path $OldFolder)) {
    New-Item -ItemType Directory -Path $OldFolder | Out-Null
}

$Log = @()

foreach ($item in $PreviewSorted) {
    $oldPath = Join-Path $Folder $item.OldFilename

    if (-not (Test-Path $oldPath)) {
        continue
    }

    $originalOldPath = Join-Path $OldFolder $item.OldFilename

    Move-Item -Path $oldPath -Destination $originalOldPath

    if (-not [string]::IsNullOrWhiteSpace($item.NewFilename)) {
        $newPath = Join-Path $Folder $item.NewFilename
        Copy-Item -Path $originalOldPath -Destination $newPath

        $status = "Renamed"
    }
    else {
        $status = "MovedToOldOnly"
    }

    $Log += [PSCustomObject]@{
        OldFilename = $item.OldFilename
        NewFilename = $item.NewFilename
        Status = $status
    }
}

$Log | Export-Csv -Path $LogFile -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "已完成。Rename log：$LogFile"
Write-Host ""

while ($true) {
    Write-Host ""
    Write-Host "請選擇下一步："
    Write-Host "1. 離開"
    Write-Host "2. 回復原狀"
    Write-Host "3. 查看未命中規則的檔案"
    $choice = Read-Host "請輸入 1 / 2 / 3"

    if ($choice -eq "1") {
        Write-Host "結束程式。"
        break
    }

    if ($choice -eq "2") {
        Write-Host "開始回復..."

        $CurrentFiles = Get-ChildItem -Path $Folder -File | Where-Object {
            $_.Name -ne "rename_log.csv"
        }

        foreach ($file in $CurrentFiles) {
            Remove-Item -Path $file.FullName -Force
        }

        $OldFiles = Get-ChildItem -Path $OldFolder -File

        foreach ($file in $OldFiles) {
            Move-Item -Path $file.FullName -Destination (Join-Path $Folder $file.Name)
        }

        Remove-Item -Path $OldFolder -Force -Recurse

        Write-Host "已回復原狀。"
        break
    }

    if ($choice -eq "3") {
        Write-Host ""
        Write-Host "未命中規則的檔案："
        $Preview | Where-Object { [string]::IsNullOrWhiteSpace($_.NewFilename) } | Format-Table -AutoSize
    }
}