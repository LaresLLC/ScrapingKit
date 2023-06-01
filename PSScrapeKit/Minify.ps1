Import-Module PSMinifier

Get-ChildItem -Filter DCScrape.ps1 | Get-Command { $_.FullName } | Compress-ScriptBlock -NoBlock -OutputPath DCScrape.min.ps1
Write-Output "[*] MINIFIED: DCScrape.ps1      -> DCScrape.min.ps1"
Get-ChildItem -Filter DCScrape.ps1 | Get-Command { $_.FullName } | Compress-ScriptBlock -NoBlock -GZip -OutputPath DCScrape.min.gzip.ps1
Write-Output "[*] GZIPPED:  DCScrape.ps1      -> DCScrape.min.gzip.ps1"
Get-ChildItem -Filter OutlookScrape.ps1 | Get-Command { $_.FullName } | Compress-ScriptBlock -NoBlock -OutputPath OutlookScrape.min.ps1
Write-Output "[*] MINIFIED: OutlookScrape.ps1 -> OutlookScrape.min.ps1"
Get-ChildItem -Filter OutlookScrape.ps1 | Get-Command { $_.FullName } | Compress-ScriptBlock -NoBlock -GZip -OutputPath OutlookScrape.min.gzip.ps1
Write-Output "[*] GZIPPED:  OutlookScrape.ps1 -> OutlookScrape.min.gzip.ps1"
