function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (	
        [parameter(Mandatory)][string] $Name,
        [parameter(Mandatory)][string] $GroupName,
        [UInt64] $RetryIntervalSec = 10,
        [UInt32] $RetryCount = 50,
        [parameter(Mandatory)]
		[PSCredential]$DomainAdministratorCredential
    )

    $retValue=@{}
    $retValue.Add("RetryIntervalSec","$RetryIntervalSec")
    $retValue.Add("RetryCount","$RetryCount")
    $retValue.Add("DomainAdministratorCredential",$DomainAdministratorCredential)
    try
    {
        $ErrorActionPreference = "Stop"
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $cluster = Get-Cluster -Name $Name
        $group = $cluster | Get-ClusterGroup -Name $GroupName
        $retValue = @{
            Name = "$($cluster.Name)"
            GroupName = "$($group.Name)"
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. Error: $($Error[0].Exception.Message)"
    }
    finally
    {
        if ($context)
        {
            $context.Undo()
            $context.Dispose()
            CloseUserToken($newToken)
        }
    }
    return $retValue
}

function Set-TargetResource
{
    param
    (	
        [parameter(Mandatory)][string] $Name,
        [parameter(Mandatory)][string] $GroupName,
        [UInt64] $RetryIntervalSec = 10,
        [UInt32] $RetryCount = 50,
        [parameter(Mandatory)]
		[PSCredential]$DomainAdministratorCredential
    )

    $clusterFound = $false
    $clusterGroupFound = $false
    Write-Verbose -Message "Checking for cluster group $GroupName in cluster $Name..."
    try
    {
        $ErrorActionPreference = "Stop"
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        for ($count = 0; $count -lt $RetryCount; $count++)
        {
                $cluster = Get-Cluster -Name $Name -ErrorAction SilentlyContinue
                if ($cluster -ne $null)
                {
                    Write-Verbose -Message "Found cluster $Name"
                    $clusterFound = $true
                    $group = $cluster | Get-ClusterGroup -Name $GroupName -ErrorAction SilentlyContinue
                    if($group -ne $null)
                    {
                        Write-Verbose -Message "Cluster group $GroupName found in cluster $Name"
                        $clusterGroupFound = $true
                        break;   
                    }
                    else
                    {
                        Write-Verbose -Message "Cluster group $GroupName not found. Will retry again after $RetryIntervalSec sec"   
                        Start-Sleep -Seconds $RetryIntervalSec
                    }
                }
                else
                {
                    Write-Verbose -Message "Cluster $Name not found."   
                    break;
                }
        }
    }
    catch
    {
        Write-Verbose -Message "Error happened. $($Error[0].Exception.Message)"
    }
    finally
    {
        if ($context)
        {
            $context.Undo()
            $context.Dispose()
            CloseUserToken($newToken)
        }
    }
    if (! $clusterGroupFound)
    {
        throw "Cluster group $GroupName not found after $count attempts with $RetryIntervalSec sec interval"
    }
}

function Test-TargetResource
{
    [OutputType([Boolean])]
    param
    (	
        [parameter(Mandatory)][string] $Name,
        [parameter(Mandatory)][string] $GroupName,
        [UInt64] $RetryIntervalSec = 10,
        [UInt32] $RetryCount = 50,
        [parameter(Mandatory)]
		[PSCredential]$DomainAdministratorCredential
    )

    Write-Verbose -Message "Checking for Cluster Group $GroupName ..."

    $retValue=$false
    try
    {
        $ErrorActionPreference="Stop"
        $resource=Get-TargetResource -Name $Name -GroupName $GroupName -RetryIntervalSec $RetryIntervalSec -RetryCount $RetryCount -DomainAdministratorCredential $DomainAdministratorCredential
        if(($resource.Name -eq $Name) -and ($resource.GroupName -eq $GroupName))
        {
            $retValue=$true
        }
    }
    catch
    {
        Write-Verbose -Message "Error occured. Error: $($Error[0].Exception.Message)"
    }
    return $retValue
}

#region Additional functions
function Get-ImpersonatetLib
{
    if ($script:ImpersonateLib)
    {
        return $script:ImpersonateLib
    }

    $sig = @'
[DllImport("advapi32.dll", SetLastError = true)]
public static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, ref IntPtr phToken);

[DllImport("kernel32.dll")]
public static extern Boolean CloseHandle(IntPtr hObject);
'@ 
   $script:ImpersonateLib = Add-Type -PassThru -Namespace 'Lib.Impersonation' -Name ImpersonationLib -MemberDefinition $sig 

   return $script:ImpersonateLib
    
}

function ImpersonateAs([PSCredential] $cred)
{
    [IntPtr] $userToken = [Security.Principal.WindowsIdentity]::GetCurrent().Token
    $userToken
    $ImpersonateLib = Get-ImpersonatetLib

    $bLogin = $ImpersonateLib::LogonUser($cred.GetNetworkCredential().UserName, $cred.GetNetworkCredential().Domain, $cred.GetNetworkCredential().Password, 
    9, 0, [ref]$userToken)
    
    if ($bLogin)
    {
        $Identity = New-Object Security.Principal.WindowsIdentity $userToken
        $context = $Identity.Impersonate()
    }
    else
    {
        throw "Can't Logon as User $cred.GetNetworkCredential().UserName."
    }
    $context, $userToken
}

function CloseUserToken([IntPtr] $token)
{
    $ImpersonateLib = Get-ImpersonatetLib

    $bLogin = $ImpersonateLib::CloseHandle($token)
    if (!$bLogin)
    {
        throw "Can't close token"
    }
}
#endregion Additional functions

Export-ModuleMember -Function *-TargetResource