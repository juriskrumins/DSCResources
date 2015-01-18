#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
    [OutputType([Hashtable])]	
    param
    (
        [parameter(Mandatory)][string] $Name,
        [UInt64] $RetryIntervalSec = 10,
        [UInt32] $RetryCount = 50
    )

    $retValue=@{}
    try
    {
        $ErrorActionPreference="Stop"
        if ((Get-PSDrive AD | Measure-Object).Count -eq 0)
        {
            New-PSDrive -Name AD -PSProvider ActiveDirectory -Root "//RootDSE/"
        }
        $ca=Get-ChildItem "AD:\CN=Certification Authorities,CN=Public Key Services,CN=Services,CN=Configuration,DC=eco2g,DC=psi-holdings,DC=com" | Where-Object {($_.ObjectClass -eq "certificationAuthority") -and ($_.Name -eq $Name)}
        if(($ca | Measure-Object).Count -ne 0)
        {
            $retValue=@{
                Name = $ca.Name
                RetryIntervalSec = $RetryIntervalSec
                RetryCount = $RetryCount
            }
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured. $($Error[0].Exception.Message)."
    }
    return $retValue
}

#
# The Set-TargetResource cmdlet.
#
function Set-TargetResource
{
    param
    (	
        [parameter(Mandatory)][string] $Name,
        [UInt64] $RetryIntervalSec = 10,
        [UInt32] $RetryCount = 50
    )

    $caFound = $false
    Write-Verbose -Message "Checking for AD CA $Name ..."
    for ($count = 0; $count -lt $RetryCount; $count++)
    {
        try
        {
            $ca = Get-TargetResource -Name $Name -RetryIntervalSec $RetryIntervalSec -RetryCount $RetryCount
            if ($ca.Count -ne 0)
            {
                Write-Verbose -Message "Found AD CA $Name"
                $caFound = $true
                break;
            }
            else
            {
                Write-Verbose -Message "AD CA $Name not found. Will retry again after $RetryIntervalSec sec"
                Start-Sleep -Seconds $RetryIntervalSec
            }
            
        }
        catch
        {
             Write-Verbose -Message "Error occured. $($Error[0].Exception.Message)"
        }
    }

    if (! $caFound)
    {
        throw "AD CA $Name not found after $count attempts with $RetryIntervalSec sec interval"
    }
}

#
# The Test-TargetResource cmdlet.
#
function Test-TargetResource
{
    [OutputType([Boolean])]
    param
    (	
        [parameter(Mandatory)][string] $Name,
        [UInt64] $RetryIntervalSec = 10,
        [UInt32] $RetryCount = 50
    )

    $retValue=$false
    Write-Verbose -Message "Checking for AD CS $Name ..."

    try
    {
        $ca=Get-TargetResource -Name $Name -RetryIntervalSec $RetryIntervalSec -RetryCount $RetryCount
        if($ca.count -ne 0)
        {
            Write-Verbose -Message "AD CA $Name found."
            $retValue=$true
        }
        else
        {
            Write-Verbose -Message "Can't find AD CA $Name"
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. $($Error[0].Exception.Message)"
    }
    return $retValue
}
