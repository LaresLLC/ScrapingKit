# DomainScrape (Offensive SysAdmin Suite) 
Domain Scrape is an extension of [ScrapingKit](https://github.com/LaresLLC/ScrapingKit) that will scrape shares for supplied keywords, think of it as SnafflerLite but more focused.

***Invoke-Scrape.ps1***


Offers users the following 2 options. 


Scrape the Domain Controller - This option will only scrape NETLOGON and SYSVOL directories.
Scrape all Domain Shares - This option only scrapes NETLOGON on the DC and then all other readable available domain shares.

SYSVOL contains Group Policies (GPP), if you don’t want to manually review them use option 1.



***Invoke-NetShareScrape.ps1***

Used to hunt for keywords in files stored across network shares, Invoke-NetShareScrape.ps1 will enumerate all shares the user that executed can access, and then scrape the following file doc formats .txt|\.ini|\.xml|\.bat|\.ps1|\.doc|\.docx|\.xlsx|\.xls for the user defined keywords.


```
PS C:\> powershell.exe -nop -exec bypass
PS C:\> Import-Module Invoke-NetShareScrape.ps1
PS C:\> Invoke-NetShareScrape

Enter initial keyword (or press enter to finish):
cat
Enter additional keyword (or press enter to finish):




ComputerName            : WIN-MS87LHLC91U
ShareName               : NETLOGON
FileName                : Game1.txt
FullName                : \\WIN-MS87LHLC91U\NETLOGON\Shares\Game1.txt
MatchingLines           : #   Description:
                          # This script disables Windows Defender. Run it once (will throw errors), then
                          # reboot, run it again (this time no errors should occur) followed by another
                          # reboot.

                          Import-Module -DisableNameChecking $PSScriptRoot\..\lib\New-FolderForced.psm1
                          Import-Module -DisableNameChecking $PSScriptRoot\..\lib\take-own.psm1

                          Write-Output "Elevating priviledges for this process"
                          do {} until (Elevate-Privileges SeTakeOwnershipPrivilege)

                          $tasks = @(
                              "\Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance"
                              "\Microsoft\Windows\Windows Defender\Windows Defender Cleanup"
                              "\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan"
                              "\Microsoft\Windows\Windows Defender\Windows Defender Verification"
                          )

                          foreach ($task in $tasks) {
                              $parts = $task.split('\')
                              $name = $parts[-1]
                              $path = $parts[0..($parts.length-2)] -join '\'

                              Write-Output "Trying to disable scheduled task $name"
                              Disable-ScheduledTask -TaskName "$name" -TaskPath "$path"
                          }

                          Write-Output "Disabling Windows Defender via Group Policies"
                          New-FolderForced -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows Defender"
                          Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" 1
                          Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows Defender" "DisableRoutinelyTakingAction" 1
                          New-FolderForced -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows Defender\Real-Time Protection"
                          Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring" 1

                          password = fishandchips1


                          Write-Output "Disabling Windows Defender Services"
                          Takeown-Registry("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WinDefend")
                          Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" "Start" 4
                          Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" "...
AdditionalKeywordsFound :

ComputerName            : WIN-MS87LHLC91U
ShareName               : NETLOGON
FileName                : Startup.bat
FullName                : \\WIN-MS87LHLC91U\NETLOGON\Shares\Brandon_DiCam\Startup.bat
MatchingLines           : param (
                              [string]$Username = 'user2',
                              [string]$Password = 'Passw0rd!'
                          )

                          $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
                          $Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)

                          $Domain = 'your_domain'
                          $Query = "SELECT * FROM Win32_ComputerSystem WHERE PartOfDomain = 'True'"

                          try {
                              $DomainHosts = Get-WmiObject -Query $Query -ComputerName $Domain -Credential $Credential
                              foreach ($Host in $DomainHosts) {
                                  Write-Output "Host: $($Host.Name)"
                              }
                          } catch {
                              Write-Output "Error occurred: $_"
                          }

AdditionalKeywordsFound :

ComputerName            : WIN-MS87LHLC91U
ShareName               : NETLOGON
FileName                : Script1.txt
FullName                : \\WIN-MS87LHLC91U\NETLOGON\Shares\Test2\Dog_Cat\Script1.txt
MatchingLines           :
                          fsfsfssf

                          cars

                          cats


                          dshdsghsdhsdhds

                          dsdsfhjsdgsdfhsdfsdf
                          sdf
                          sdf
                          dsds
                          dsds
                          ds
                          sd
                          sd
                          hhgghadgadgadgadsad
                          das






                          username=User23&password=Superdope1


                          sdhdsdsdsds
AdditionalKeywordsFound :

ComputerName            : WIN-MS87LHLC91U
ShareName               : NETLOGON
FileName                : Script3.txt
FullName                : \\WIN-MS87LHLC91U\NETLOGON\Shares\Test2\Dog_Cat\Script3.txt
MatchingLines           : "åŠ‡å›£å››å­£ãƒŸãƒ¥ãƒ¼ã‚¸ã‚«ãƒ«ã€Žã‚­ãƒ£ãƒƒãƒ„ã€ãƒ¡ãƒ¢ãƒªã‚¢ãƒ«ã‚¨ãƒ‡ã‚£ã‚·ãƒ§ãƒ³" (in Japanese). Oricon. Archived from the original on 3 May 2019. Retrieved 3 May 2019.
                          "Musical â€“ Cats (Nederlandstalige Versie 1987)" (in Dutch). Dutch Charts. Retrieved 29 April 2019.
                          "charts.nz â€“ Search for: cats". New Zealand charts portal. Retrieved 30 April 2019.
                          "Official Albums Chart Results Matching: Cats". Official Charts Company. Retrieved 30 April 2019.
                          "Stage Cast Recordings: Cats (London)". British Phonographic Industry. Retrieved 25 March 2019.
                          Grein, Paul (24 July 1982). "Geffen Putting Emphasis On Broadway Productions". Billboard. Vol. 94, no. 29. p. 68. ISSN 0006-2510.
                          "Original London Cast: Cats [Original London Cast Recording]". AllMusic. Archived from the original on 24 March 2019. Retrieved 19 October 2013.
                          "Original Cast Recording: Cats". British Phonographic Industry. Retrieved 30 April 2019.
                          "Edelmetall â€“ Suche nach: cats". Swiss Hitparade. Retrieved 30 April 2019.
                          Culwell-Block, Logan. "The Definitive List of the 42 Best-Selling Cast Recordings of All Time". Playbill. Archived from the original on 24 March 2019. Retrieved 25 March 2019.
                          "Cats (Original Cast)". Recording Industry Association of America. Archived from the original on 24 March 2019. Retrieved 25 March 2019.
                          "Musical â€“ Cats (Wien)" (in German). Universal Music Austria. Archived from the original on 29 April 2019. Retrieved 29 April 2019.
                          Sampson, Jim (16 March 1985). "Special Report: West Germany, Austria, Switzerland ...Newsline..." Billboard. Vol. 97, no. 11. p. 9. ISSN 0006-2510.
                          "Cats â€“ Theater ad Vienna" (in German). Bundesverband Musikindustrie. Retrieved 30 April 2019.
                          "Cats sound recording: the original Australian cast". Trove. Archived from the original on 25 March 2019. Retrieved 25 March 2019.
                          "åŠ‡å›£å››å­£ãƒŸãƒ¥ãƒ¼ã‚¸ã‚«ãƒ« CATS ã‚ªãƒªã‚¸ãƒŠãƒ«ãƒ»ã‚­ãƒ£ã‚¹ãƒˆ" [Gekidan Shiki Musical CATS Original Cast] (in Japanese). Amazon. Archived from the original on 26 M...
AdditionalKeywordsFound :

ComputerName            : LABLAB-PC1
ShareName               : The-Shares
FileName                : Look1.txt
FullName                : \\LABLAB-PC1\The-Shares\Look1.txt
MatchingLines           : ffdfdfffdfdfdfdf
                          dfgf
                          dgf
                          gdg
                          dgdggddggd


                          golf

                          fdfd
                          dffdfd



                          password is Catman1

```
