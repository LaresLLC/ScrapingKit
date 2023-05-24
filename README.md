# ScrapingKit
Scraping Kit is made up of several tools for scraping services for keywords, useful for initial enumeration of Domain Controllers or if you have popped a user's desktop, their outlook client. Each component has a function currently supports scraping and emailing the contents to a designated email address for easy exfiltration.

The kit contains three tools currently with more to come in the coming months and more customisation options.

- OutlookScraper
- DCScraper
- Outlook_and_DC_Scraper_Combined
## Outlook Scraper

### What it is

### How to setup/use

## DC Scraper

### What it is

It helps identify files that contain specific keywords in the Policies and Scripts directories within the SYSVOL folder of an Active Directory domain. It then provides information about the matches and can be used to hunt for potential words such as username and password present in those files.

### How to setup/use

## Outlook and DC Scraper Combined

### What it is

It’s a combination of both console applications with the functions selected via menu driven options. This can scrape the DC or emails for chosen keywords.

### How to setup/use

Read this blog post for more detailed information Add-Link

Compile then execute with either PowerShell, CMD or if you have physical access simply double click it.
The following menu screen will load.
Please select an option:
1. Run Outlook Email Search
2. Run Active Directory Keyword Search
3. Exit

