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
        $AppPoolProcessModelIdleTimeout
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
            AppPoolProcessModelIdleTimeout = ($AppPool.processModel.idleTimeout).TotalMinutes
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
        $AppPoolProcessModelIdleTimeout
    )


    $AppPool = Get-TargetResource -AppPoolName $AppPoolName -AppPoolProcessModelIdleTimeout $AppPoolProcessModelIdleTimeout
    if($AppPool.Count -ne 0)
    {
        Write-Verbose -Message "Setting up App Pool $AppPoolName ProcessModelIdleTimeout to $AppPoolProcessModelIdleTimeout ..."
        $AppPool = Get-Item "IIS:\AppPools\$AppPoolName"
        $timespan=New-TimeSpan -Minutes $AppPoolProcessModelIdleTimeout
        $AppPool.processModel.idleTimeout=$timespan
        $AppPool | Set-Item
        Write-Verbose -Message "App Pool $AppPoolName ProcessModelIdleTimeout have been set to $AppPoolProcessModelIdleTimeout ."
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
        $AppPoolProcessModelIdleTimeout
    )

    $retValue=$false
    $AppPool = Get-TargetResource -AppPoolName $AppPoolName -AppPoolProcessModelIdleTimeout $AppPoolProcessModelIdleTimeout
    if($AppPool.Count -ne 0)
    {
        if($AppPool.AppPoolProcessModelIdleTimeout -eq $AppPoolProcessModelIdleTimeout)
        {
            Write-Verbose -Message "Application pool $AppPoolName exists and ProcessModelIdleTimeout set correctly."
            $retValue=$true
        }
        else
        {
            Write-Verbose -Message "Application pool $AppPoolName exists, but ProcessModelIdleTimeout set incorrectly. We'll adjust it."
        }
    }
    else
    {
        Write-Verbose -Message "Can't find application pool $AppPoolName ."
    }

    return $retValue
}


Export-ModuleMember -Function *-TargetResource