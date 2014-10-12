function Get-TargetResource
{
    param
    (	
        [parameter(Mandatory)][string] $Name,
        [parameter(Mandatory)][string] $GroupName,
        [UInt64] $RetryIntervalSec = 10,
        [UInt32] $RetryCount = 50
    )

    try
    {
        @{
            Name = "$((Get-Cluster -Name $Name).Name)"
            GroupName = "$((Get-Cluster -Name $Name | Get-ClusterGroup -Name $GroupName).Name)"
            RetryIntervalSec = $RetryIntervalSec
            RetryCount = $RetryCount
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. Error: $($Error[0].Exception.Message)"
    }
}

function Set-TargetResource
{
    param
    (	
        [parameter(Mandatory)][string] $Name,
        [parameter(Mandatory)][string] $GroupName,
        [UInt64] $RetryIntervalSec = 10,
        [UInt32] $RetryCount = 50
    )

    $clusterFound = $false
    Write-Verbose -Message "Checking for cluster group $GroupName in cluster $Name..."

    for ($count = 0; $count -lt $RetryCount; $count++)
    {
        try
        {
            $ComputerInfo = Get-WmiObject Win32_ComputerSystem
            if (($ComputerInfo -eq $null) -or ($ComputerInfo.Domain -eq $null))
            {
                Write-Verbose -Message "Can't find machine's domain name"
                break;
            }

            $cluster = Get-Cluster -Name $Name -Domain $ComputerInfo.Domain

            if ($cluster -ne $null)
            {
                Write-Verbose -Message "Found cluster $Name"
                $clusterFound = $true

                break;
            }
            
        }
        catch
        {
             Write-Verbose -Message "Cluster $Name not found. Will retry again after $RetryIntervalSec sec"
        }
            
        Write-Verbose -Message "Cluster $Name not found. Will retry again after $RetryIntervalSec sec"
        Start-Sleep -Seconds $RetryIntervalSec
    }

    if (! $clusterFound)
    {
        throw "Cluster $Name not found after $count attempts with $RetryIntervalSec sec interval"
    }
}

function Test-TargetResource
{
    param
    (	
        [parameter(Mandatory)][string] $Name,
        [parameter(Mandatory)][string] $GroupName,
        [UInt64] $RetryIntervalSec = 10,
        [UInt32] $RetryCount = 50
    )

    Write-Verbose -Message "Checking for Cluster Group $GroupName ..."

    try
    {
        $ErrorActionPreference="Stop"
        $resource=Get-TargetResource -Name $Name -GroupName $GroupName -RetryIntervalSec $RetryIntervalSec -RetryCount $RetryCount
        return (($resource.Name -eq $Name) -and ($resource.GroupName -eq $GroupName))
    }
    catch
    {
        Write-Verbose -Message "Error occured. Error: $($Error[0].Exception.Message)"
        $false
    }
}
