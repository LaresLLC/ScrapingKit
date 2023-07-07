
<#

Scrapes domain controller NETLOGON but not SYSVOL for all key words and also searches all domain shares for same keywords.

#>


function Invoke-NetShareScrape {

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

}