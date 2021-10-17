Param
(
    [System.IO.DirectoryInfo]$targetDir=".",
    [System.IO.DirectoryInfo]$outputDir=".."
)

$wshShell = New-Object -ComObject WScript.Shell
$depth = $depthStack = 1

function Get-UrlsHierarchically($dir)
{
    $urls = @{}
    
    $urls["CURRENT_DIR"] = @()
    foreach($item in (Get-ChildItem $dir))
    {
        if($item -is [System.IO.DirectoryInfo])
        {
            $script:depthStack++
            if($script:depthStack -gt $script:depth)
            {
                $script:depth = $script:depthStack
            }
            $urls[$item.Name] = Get-UrlsHierarchically($item)
            $script:depthStack--
        }
        else
        {
            $urls["CURRENT_DIR"] += $wshShell.CreateShortcut($item).TargetPath
        }
    }

    return $urls
}

Write-Host "Target location: $($targetDir.FullName)"
Write-Host "Output location: $($outputDir.FullName)"

$result = Get-UrlsHierarchically(Get-Item $targetDir)
ConvertTo-Json $result -Depth $depth > (Join-Path $outputDir "UrlsResult.json")

Write-Host ("-" * 30)
Write-Host "Finish"
