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
        [ValidateSet("Classic","Integrated")]
        [System.String]
        $AppPoolManagedPipelineMode
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
            AppPoolManagedPipelineMode = $AppPool.managedPipelineMode
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
        [ValidateSet("Classic","Integrated")]
        [System.String]
        $AppPoolManagedPipelineMode
    )


    $AppPool = Get-TargetResource -AppPoolName $AppPoolName -AppPoolManagedPipelineMode $AppPoolManagedPipelineMode
    if($AppPool.Count -ne 0)
    {
        Write-Verbose -Message "Setting up App Pool $AppPoolName ManagedPipelineMode to $AppPoolManagedPipelineMode ..."
        $AppPool = Get-Item "IIS:\AppPools\$AppPoolName"
        $AppPool.managedPipelineMode = "$AppPoolManagedPipelineMode"
        $AppPool | Set-Item
        Write-Verbose -Message "App Pool $AppPoolName ManagedPipelineMode have been set to $AppPoolManagedPipelineMode ."
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
        [ValidateSet("Classic","Integrated")]
        [System.String]
        $AppPoolManagedPipelineMode
    )

    $retValue=$false
    $AppPool = Get-TargetResource -AppPoolName $AppPoolName -AppPoolManagedPipelineMode $AppPoolManagedPipelineMode
    if($AppPool.Count -ne 0)
    {
        if($AppPool.AppPoolManagedPipelineMode -eq $AppPoolManagedPipelineMode)
        {
            Write-Verbose -Message "Application pool $AppPoolName exists and ManagedPipelineMode set correctly."
            $retValue=$true
        }
        else
        {
            Write-Verbose -Message "Application pool $AppPoolName exists, but ManagedPipelineMode set incorrectly. We'll adjust it."
        }
    }
    else
    {
        Write-Verbose -Message "Can't find application pool $AppPoolName ."
    }

    return $retValue
}


Export-ModuleMember -Function *-TargetResource