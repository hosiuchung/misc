# Convert Internet Shortcuts To Json

Convert internet shortcuts `.url` to a JSON file according to folder structure in the target location with PowerShell in Windows.

## Usage

### Directory tree

```powershell
PS D:\example> tree /f

D:.
│   Microsoft.url
│
└───sub-dir
    │   Google.url
    │
    └───sub-sub-dir
            Apple.url
```

### Run script

```powershell
PS D:\misc\ConvertInternetShortcutsToJson> .\Convert-InternetShortcuts.ps1 D:\example\ D:\
```

### Output

```json
{
    "CURRENT_DIR": ["https://www.microsoft.com/en-us"],
    "sub-dir": {
        "CURRENT_DIR": ["https://www.google.com.hk/"],
        "sub-sub-dir": {
            "CURRENT_DIR": ["https://www.apple.com/"]
        }
    }
}
```

## Note

### Pipeline captured variable is not affected by upstream

When passing the variable `$depth` to pipeline:

```powershell
Get-UrlsHierarchically(Get-Item $targetDir) | ConvertTo-Json -Depth $depth > (Join-Path $outputDir "UrlsResult.json")
```

`ConvertTo-Json` warn if the depth of directory is greater than 1:

```
WARNING: Resulting JSON is truncated as serialization has exceeded the set depth of 1.
```

It is because PowerShell interpret the line immediately before `$depth` is updated by the function `Get-UrlsHierarchically`. It means the initial value `1` will be captured.

To avoid this, changed the code as below:

```powershell
$result = Get-UrlsHierarchically(Get-Item $targetDir)
ConvertTo-Json $result -Depth $depth > (Join-Path $outputDir "UrlsResult.json")
```

### Variable Scope is distinguished by parent and child

PowerShell is using parent and child scope to distinguish the variable scope instead of block level. It means the variable scope is affected by function and script but not for-block nor if-block etc.

If a function need to access outside variable in the same script, use scope modifier `script:` (e.g. `$script:depth`)

For more information, [about Scopes - PowerShell | Microsoft Docs](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scopes?view=powershell-7.1#parent-and-child-scopes)

### Reference

-   [Get target of shortcut (.lnk) file with powershell - Stack Overflow](https://stackoverflow.com/questions/42762122/get-target-of-shortcut-lnk-file-with-powershell)

-   [powershell - Unexpected ConvertTo-Json results? Answer: it has a default -Depth of 2 - Stack Overflow](https://stackoverflow.com/questions/53583677/unexpected-convertto-json-results-answer-it-has-a-default-depth-of-2)
