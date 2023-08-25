<#
author: james romeo gaspar
version 1.0 19 August 2023
Generate GPOReport.html from all GPOs
Extract Value under Software Restriction Policies/Additional Rules
Output to TxT file
revision 2.0 26 August 2023
Extracted values under Software Restriction Policies/Additional Rules
(Path, Security Level and Date Last Modified)
Output to CSV file
#>

$allGPOs = Get-GPO -All

$reportFolderPath = "C:\Temp\GPOReports"

if (-not (Test-Path -Path $reportFolderPath -PathType Container)) {
    New-Item -Path $reportFolderPath -ItemType Directory
}

$totalGPOs = $allGPOs.Count
$completedGPOs = 0

foreach ($gpo in $allGPOs) {
    $cleanedDisplayName = $gpo.DisplayName -replace '[\\/:*?"<>|]', '_'

    $reportFileName = "${cleanedDisplayName}_Report.html"
    $reportFilePath = Join-Path -Path $reportFolderPath -ChildPath $reportFileName
    $gpoReport = Get-GPOReport -Name $gpo.DisplayName -ReportType HTML

    $gpoReport | Out-File -FilePath $reportFilePath -Force

    $completedGPOs++
    $percentComplete = ($completedGPOs / $totalGPOs) * 100
    $statusMessage = "Generating GPO reports..."
    
    Write-Progress -Activity $statusMessage -Status "Processing GPO: $($gpo.DisplayName)" -PercentComplete $percentComplete
}

Write-Host "GPO reports saved in $reportFolderPath ready for processing"

$htmlFilesFolder = "C:\Temp\GPOReports"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFileName = "outputGPOscan_$timestamp.csv"
$logsFolderPath = Join-Path -Path $htmlFilesFolder -ChildPath "Logs"

if (-not (Test-Path -Path $logsFolderPath -PathType Container)) {
    New-Item -Path $logsFolderPath -ItemType Directory
}

$outputFilePath = Join-Path -Path $logsFolderPath -ChildPath $outputFileName
$htmlFilePaths = Get-ChildItem -Path $htmlFilesFolder -Filter *.html | Select-Object -ExpandProperty FullName

$outputData = @()
$currentFileIndex = 0

foreach ($htmlFilePath in $htmlFilePaths) {
    $currentFileIndex++
    $processingMessage = "Processing file $currentFileIndex of $($htmlFilePaths.Count): $($htmlFilePath)"
    Write-Host $processingMessage

    $htmlContent = Get-Content -Path $htmlFilePath -Raw
    $sectionTitle = "Software Restriction Policies/Additional Rules"
    $startIndex = $htmlContent.IndexOf($sectionTitle)

    if ($startIndex -ne -1) {
        $startIndex = $startIndex + $sectionTitle.Length
        $sectionContent = $htmlContent.Substring($startIndex)

        $pathPattern = '<tr><td><b>([^<]*)<\/b><\/td><\/tr>'
        $pathMatches = [Regex]::Matches($sectionContent, $pathPattern)

        $securityLevelPattern = '<tr><td scope="row">Security Level<\/td><td>(.*?)<\/td><\/tr>'
        $securityLevelMatch = [Regex]::Match($sectionContent, $securityLevelPattern)
        $securityLevel = if ($securityLevelMatch.Success) { $securityLevelMatch.Groups[1].Value } else { 'N/A' }

        $lastModifiedPattern = '<tr><td scope="row">Date last modified<\/td><td>(.*?)<\/td><\/tr>'
        $lastModifiedMatch = [Regex]::Match($sectionContent, $lastModifiedPattern)
        $lastModified = if ($lastModifiedMatch.Success) { $lastModifiedMatch.Groups[1].Value } else { 'N/A' }

        if ($pathMatches.Count -eq 0) {
            $outputData += [PSCustomObject]@{
                'GPO Path' = $htmlFilePath
                'Item' = $sectionTitle
                'Path' = 'N/A'
                'Security Level' = $securityLevel
                'Date Last Modified' = $lastModified
            }
        } else {
            foreach ($pathMatch in $pathMatches) {
                $pathValue = $pathMatch.Groups[1].Value
                $outputData += [PSCustomObject]@{
                    'GPO Path' = $htmlFilePath
                    'Item' = $sectionTitle
                    'Path' = $pathValue
                    'Security Level' = $securityLevel
                    'Date Last Modified' = $lastModified
                }
            }
        }
    } else {
        $outputData += [PSCustomObject]@{
            'GPO Path' = $htmlFilePath
            'Item' = 'Section Not Found'
            'Path' = 'N/A'
            'Security Level' = 'N/A'
            'Date Last Modified' = 'N/A'
        }
    }
}

$outputData | Export-Csv -Path $outputFilePath -NoTypeInformation

Write-Host "Completed processing GPO Reports"
Write-Host "Output has been saved to $($outputFilePath)"
