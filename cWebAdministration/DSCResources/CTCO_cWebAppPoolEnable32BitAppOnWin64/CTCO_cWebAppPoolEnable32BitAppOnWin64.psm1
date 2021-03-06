function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $AppPoolName,

        [parameter(Mandatory = $true)]
        [Boolean]
        $AppPoolEnable32BitAppOnWin64
    )

    $returnValue = @{}
    #need to import explicitly to run for IIS:\AppPools
    Import-Module WebAdministration

    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw "Please ensure that WebAdministration module is installed."
    }

    Write-Verbose -Message "Getting Application Pool info ..."
    $AppPool = Get-Item "IIS:\AppPools\*" | Where-Object {$_.Name -eq $AppPoolName}
    Write-Verbose -Message "Application Pool collected."
    if($AppPool -ne $null)
    {
        $returnValue = @{
            AppPoolName   = $AppPool.Name
            AppPoolEnable32BitAppOnWin64 = $AppPool.enable32BitAppOnWin64
        }
    }
    else
    {
        Write-Verbose -Message "Can't find application pool $AppPoolName ."
    }

    return $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $AppPoolName,

        [parameter(Mandatory = $true)]
        [Boolean]
        $AppPoolEnable32BitAppOnWin64
    )


    $AppPool = Get-TargetResource -AppPoolName $AppPoolName -AppPoolEnable32BitAppOnWin64 $AppPoolEnable32BitAppOnWin64
    if($AppPool.Count -ne 0)
    {
        Write-Verbose -Message "Setting up App Pool $AppPoolName Enable32BitAppOnWin64 to $AppPoolEnable32BitAppOnWin64 ..."
        $AppPool = Get-Item "IIS:\AppPools\$AppPoolName"
        $AppPool.enable32BitAppOnWin64 = "$AppPoolEnable32BitAppOnWin64"
        $AppPool | Set-Item
        Write-Verbose -Message "App Pool $AppPoolName Enable32BitAppOnWin64 have been set to $AppPoolEnable32BitAppOnWin64 ."
    }
    else
    {
        Write-Verbose -Message "Can't find application pool $AppPoolName ."
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $AppPoolName,

        [parameter(Mandatory = $true)]
        [Boolean]
        $AppPoolEnable32BitAppOnWin64
    )

    $retValue=$false
    $AppPool = Get-TargetResource -AppPoolName $AppPoolName -AppPoolEnable32BitAppOnWin64 $AppPoolEnable32BitAppOnWin64
    if($AppPool.Count -ne 0)
    {
        if($AppPool.AppPoolEnable32BitAppOnWin64 -eq $AppPoolEnable32BitAppOnWin64)
        {
            Write-Verbose -Message "Application pool $AppPoolName exists and Enable32BitAppOnWin64 set correctly."
            $retValue=$true
        }
        else
        {
            Write-Verbose -Message "Application pool $AppPoolName exists, but Enable32BitAppOnWin64 set incorrectly. We'll adjust it."
        }
    }
    else
    {
        Write-Verbose -Message "Can't find application pool $AppPoolName ."
    }

    return $retValue
}


Export-ModuleMember -Function *-TargetResource