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
        [system.int64]
        $AppPoolRecyclingPeriodicRestartTime
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
            AppPoolRecyclingPeriodicRestartTime = ($AppPool.recycling.periodicrestart.time).TotalMinutes
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
        [system.int64]
        $AppPoolRecyclingPeriodicRestartTime
    )


    $AppPool = Get-TargetResource -AppPoolName $AppPoolName -AppPoolRecyclingPeriodicRestartTime $AppPoolRecyclingPeriodicRestartTime
    if($AppPool.Count -ne 0)
    {
        Write-Verbose -Message "Setting up App Pool $AppPoolName RecyclingPeriodicRestartTime to $AppPoolRecyclingPeriodicRestartTime ..."
        $AppPool = Get-Item "IIS:\AppPools\$AppPoolName"
        $timespan=New-TimeSpan -Minutes $AppPoolRecyclingPeriodicRestartTime
        $AppPool.recycling.periodicrestart.time=$timespan
        $AppPool | Set-Item
        Write-Verbose -Message "App Pool $AppPoolName RecyclingPeriodicRestartTime have been set to $AppPoolRecyclingPeriodicRestartTime ."
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
        [system.int64]
        $AppPoolRecyclingPeriodicRestartTime
    )

    $retValue=$false
    $AppPool = Get-TargetResource -AppPoolName $AppPoolName -AppPoolRecyclingPeriodicRestartTime $AppPoolRecyclingPeriodicRestartTime
    if($AppPool.Count -ne 0)
    {
        if($AppPool.AppPoolRecyclingPeriodicRestartTime -eq $AppPoolRecyclingPeriodicRestartTime)
        {
            Write-Verbose -Message "Application pool $AppPoolName exists and RecyclingPeriodicRestartTime set correctly."
            $retValue=$true
        }
        else
        {
            Write-Verbose -Message "Application pool $AppPoolName exists, but RecyclingPeriodicRestartTime set incorrectly. We'll adjust it."
        }
    }
    else
    {
        Write-Verbose -Message "Can't find application pool $AppPoolName ."
    }

    return $retValue
}


Export-ModuleMember -Function *-TargetResource