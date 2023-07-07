function Invoke-Scrape {

function Show-Menu {
    Clear-Host
    Write-Host "=== Menu ==="
    Write-Host "1. Scrape the Domain Controller"
    Write-Host "2. Scrape all Domain Shares"
    Write-Host "Q. Quit"
    Write-Host
}
# Check for -ExcludeDCs option
$excludeDCs = $false
if ($args -contains "-ExcludeDCs") {
    $excludeDCs = $true
    Write-Host "Excluding domain controllers..."
}

function SkipDCs {
    if ($excludeDCs) {
        Write-Host "Skipping domain controller scrape due to -ExcludeDCs option."
        return
    }
    Write-Host "Scraping the DC..."
function SearchForKeywords {
    param (
        [string[]]$initialKeywords,
        [string]$domain = $env:USERDNSDOMAIN,
        [string[]]$additionalKeywords
    )

    $domainController = ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()).DomainControllers | Select-Object -First 1
    $netlogonPath = "\\$($domainController.Name)\SYSVOL\$domain"
    $matchesFound = $false
    $matchedFileNames = @()

	Get-ChildItem -Path $netlogonPath -Recurse -File | Where-Object { $_.Name -notin @('GptTmpl.inf', 'GPT.INI', 'Registry.pol') -and $_.Extension -match '^(?:\.txt|\.ini|\.xml|\.bat|\.ps1|\.doc|\.docx|\.xlsx|\.xls)$' } | ForEach-Object {
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

    Write-Host "Script 1 executed!"
    Read-Host "Press Enter to return to the menu"
}

function Execute-Script2 {
    Write-Host "Scraping all Domain Shares..."
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class Netapi32 {
    [DllImport("Netapi32.dll")]
    public static extern int DsRoleGetPrimaryDomainInformation(
        string lpServer,
        int InfoLevel,
        out IntPtr Buffer
    );

    [DllImport("Netapi32.dll")]
    public static extern int NetApiBufferFree(IntPtr Buffer);

    [DllImport("Netapi32.dll", CharSet = CharSet.Unicode)]
    public static extern int NetShareEnum(
        string serverName,
        int level,
        ref IntPtr bufPtr,
        int prefMaxLen,
        ref int entriesRead,
        ref int totalEntries,
        ref int resumeHandle
    );
}

[StructLayout(LayoutKind.Sequential)]
public struct DSROLE_PRIMARY_DOMAIN_INFO_BASIC {
    public IntPtr DomainNameFlat;
    public int DomainRole;
    public IntPtr DomainNameDns;
    public IntPtr DomainForestName;
    public int Flags;
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct SHARE_INFO_1 {
    [MarshalAs(UnmanagedType.LPWStr)]
    public string shi1_netname;
    public uint shi1_type;
    [MarshalAs(UnmanagedType.LPWStr)]
    public string shi1_remark;
}

public class SHARE_INFO_1_Helper {
    public static int GetSize() {
        return Marshal.SizeOf(typeof(SHARE_INFO_1));
    }
}
'@

function IsDomainController {
    $domainControllerRole = 3  # DSROLE_PRIMARY_DOMAIN_INFO_BASIC.DomainRole for a domain controller

    $bufferPtr = [IntPtr]::Zero
    $result = [Netapi32]::DsRoleGetPrimaryDomainInformation($null, 0, [ref]$bufferPtr)

    if ($result -eq 0 -and $bufferPtr -ne [IntPtr]::Zero) {
        $domainInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($bufferPtr, [type][DSROLE_PRIMARY_DOMAIN_INFO_BASIC])

        if ($domainInfo.DomainRole -eq $domainControllerRole) {
            return $true
        }
    }

    if ($bufferPtr -ne [IntPtr]::Zero) {
        [Netapi32]::NetApiBufferFree($bufferPtr)
    }

    return $false
}

function Get-Shares {
    [OutputType('ShareInfo')]
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [Alias('HostName', 'dnshostname', 'name')]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $ComputerName = $null
    )

    BEGIN {
        if (-not $ComputerName) {
            $adSearcher = [adsisearcher]'(objectCategory=computer)'
            $adSearcher.SearchScope = 'Subtree'
            $adSearcher.PageSize = 1000
            $adSearcher.PropertiesToLoad.AddRange(@('name'))
            $ComputerName = $adSearcher.FindAll() | ForEach-Object { $_.Properties['name'][0] }
        }
    }

    PROCESS {
        foreach ($DomainHost in $ComputerName) {
            $QueryLevel = 1
            $PtrInfo = [IntPtr]::Zero
            $EntriesRead = 0
            $TotalRead = 0
            $ResumeHandle = 0

            $Result = [Netapi32]::NetShareEnum($DomainHost, $QueryLevel, [ref]$PtrInfo, -1, [ref]$EntriesRead, [ref]$TotalRead, [ref]$ResumeHandle)
            $Offset = $PtrInfo.ToInt64()

            if (($Result -eq 0) -and ($Offset -gt 0)) {
                $Increment = [SHARE_INFO_1_Helper]::GetSize()

                for ($i = 0; $i -lt $EntriesRead; $i++) {
                    $NewIntPtr = New-Object System.IntPtr -ArgumentList $Offset
                    $Info = [System.Runtime.InteropServices.Marshal]::PtrToStructure($NewIntPtr, [type][SHARE_INFO_1])

                    if (($Info.shi1_netname -ne 'ADMIN$') -and ($Info.shi1_netname -ne 'C$') -and ($Info.shi1_netname -ne 'IPC$')) {
                        "\\$DomainHost\$($Info.shi1_netname)"
                    }

                    $Offset += $Increment
                }

                $Null = [Netapi32]::NetApiBufferFree($PtrInfo)
            }
            else {
                Write-Verbose "[Get-Shares] Error: $(([ComponentModel.Win32Exception] $Result).Message)"
            }
        }
    }
}

function PromptForCustomKeywords {
    [CmdletBinding()]
    param (
        [Switch]$ExcludeCurrentMachine
    )

    $computerName = $env:COMPUTERNAME
    $currentMachinePath = "\\$computerName"

    $keywords = @()

    Write-Host "Enter initial keyword (or press enter to finish):"
    $keyword = Read-Host

    while ($keyword -ne '') {
        $keywords += $keyword
        Write-Host "Enter additional keyword (or press enter to finish):"
        $keyword = Read-Host
    }

    Write-Host

    $shares = Get-Shares

    foreach ($share in $shares) {
        $sharePath = "\\$($share.Split('\')[2])\$($share.Split('\')[3])"

        if ($excludeCurrentMachine -and ($sharePath -eq $currentMachinePath)) {
            continue
        }

        try {

			Get-ChildItem -LiteralPath $sharePath -Recurse -File -ErrorAction Stop | Where-Object { $_.Name -notin @('GptTmpl.inf', 'GPT.INI', 'Registry.pol') -and $_.Extension -match '^(?:\.txt|\.ini|\.xml|\.bat|\.ps1|\.doc|\.docx|\.xlsx|\.xls)$' } | ForEach-Object {
                $fileContent = Get-Content -LiteralPath $_.FullName -Raw

                $matchingLines = $fileContent | Select-String -Pattern $keywords -SimpleMatch -CaseSensitive:$false

                if ($matchingLines) {
                    $matchingWords = ($matchingLines.Line | Select-String -Pattern $keywords -SimpleMatch -CaseSensitive:$false -AllMatches).Matches.Value -join ' '

                    [PSCustomObject]@{
                        ComputerName = $share.Split('\')[2]
                        ShareName = $share.Split('\')[3]
                        FileName = $_.Name
                        FullName = $_.FullName
                        MatchingLines = if ($matchingLines.Line.Length -le 2000) { $matchingLines.Line } else { $matchingLines.Line.Substring(0, 2000) + "..." }
                        AdditionalKeywordsFound = $matchingWords
                    }
                }
            }
        }
        catch {
            Write-Verbose "[PromptForCustomKeywords] Error accessing share '$sharePath': $($_.Exception.Message)"
        }
    }
}

PromptForCustomKeywords -ExcludeCurrentMachine

    Write-Host "Script 2 executed!"
    Read-Host "Press Enter to return to the menu"
}

$exitMenu = $false

do {
    Show-Menu
    $input = Read-Host "Enter your choice"

    switch ($input) {
        '1' {
            SkipDCs
            break
        }
        '2' {
            Execute-Script2
            break
        }
        'Q' {
            $exitMenu = $true
            break
        }
        default {
            Write-Host "Invalid input. Please try again."
            Pause
        }
    }
} while (-not $exitMenu)


}
