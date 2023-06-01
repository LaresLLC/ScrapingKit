# PSScrapeKit

To compile, install the following Powershell Module:

```powershell
Install-Module PSMinifier
```

Then run the `Minify.ps1` script within the PSScrapeKit directory:

```
PS /Users/alex/Code/ScrapingKit/PSScrapeKit> ./Minify.ps1
[*] MINIFIED: DCScrape.ps1      -> DCScrape.min.ps1
[*] GZIPPED:  DCScrape.ps1      -> DCScrape.min.gzip.ps1
[*] MINIFIED: OutlookScrape.ps1 -> OutlookScrape.min.ps1
[*] GZIPPED:  OutlookScrape.ps1 -> OutlookScrape.min.gzip.ps1
PS /Users/alex/Code/ScrapingKit/PSScrapeKit>
```
