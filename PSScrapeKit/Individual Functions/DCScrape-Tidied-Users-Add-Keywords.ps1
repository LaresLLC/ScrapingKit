function SearchForKeywords {
    param (
        [string[]]$initialKeywords,
        [string[]]$additionalKeywords
    )

    $domain = $env:USERDNSDOMAIN
    $domainController = ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()).DomainControllers | Select-Object -First 1
    $netlogonPath = "\\$($domainController.Name)\SYSVOL\$domain"
    $matchesFound = $false
    $matchedFileNames = @()

    Get-ChildItem -Path $netlogonPath -Recurse -File | Where-Object { $_.Name -notin @('GptTmpl.inf', 'GPT.INI', 'Registry.pol') } | ForEach-Object {
        $content = Get-Content $_.FullName

        foreach ($line in $content) {
            $initialMatches = $initialKeywords | Where-Object { $line -like "*$_*" }
            $additionalMatches = $additionalKeywords | Where-Object { $line -like "*$_*" }

            if ($initialMatches -or $additionalMatches) {
                $matchesFound = $true;

                $contextStart = [Math]::Max(0, [Array]::IndexOf($content, $line) - 3)
                $contextEnd = [Math]::Min([Array]::IndexOf($content, $line) + 3, $content.Count - 1)
                $context = $content[$contextStart..$contextEnd]

                $additionalKeywordsFound = $additionalKeywords | Where-Object { $context -cmatch "(?i)$_" }

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

                if ($_.Name -notin $matchedFileNames) {
                    $matchedFileNames += $_.Name

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
    }

    if (-not $matchesFound) {
        Write-Host "No matches found."
    }
}

function PromptForCustomKeywords {
    $initialKeywords = @()
    $additionalKeywords = @()

    do {
        $keyword = Read-Host "Enter initial keyword (or press enter to finish)"
        if (![string]::IsNullOrEmpty($keyword)) {
            $initialKeywords += $keyword
        }
    } while (![string]::IsNullOrEmpty($keyword))

    SearchForKeywords -initialKeywords $initialKeywords -additionalKeywords $additionalKeywords
}

function ShowMenu {
    Write-Host "1. Use default keywords"
    Write-Host "2. Enter custom keywords"
    Write-Host "0. Exit"

    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" {
            $initialKeywords = @(
                'password', 'cpassword', 'passw', 'cred',
                'Password', 'Cpassword', 'Passw', 'Cred',
                'Password:', 'password:', 'Password=',
                'password=', 'password ', 'cpassword ',
                'passw ', 'cred ', 'Password ', 'Cpassword ',
                'Passw ', 'Cred ', 'Password: ', 'password: ',
                'Password= ', 'password= ', 'Password : ',
                'password : ', 'Password = ', 'password = '
            )
            $additionalKeywords = @(
                'user', 'username', 'name', 'User',
                'Username', 'Name', 'Username:', 'username:',
                'Username=', 'username=', 'user ', 'username ',
                'name ', 'User ', 'Username ', 'Name ',
                'Username: ', 'username: ', 'Username= ',
                'username= ', 'Username : ', 'username : ',
                'Username = ', 'username = '
            )

            SearchForKeywords -initialKeywords $initialKeywords -additionalKeywords $additionalKeywords
        }
        "2" {
            PromptForCustomKeywords
        }
        "0" {
            # Exit
        }
        default {
            Write-Host "Invalid choice. Please try again."
            ShowMenu
        }
    }
}

ShowMenu
