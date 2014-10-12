﻿#
# cWaitForNLBCluster: DSC Resource that will wait for given name of NLB Cluster, it checks the state of the cluster for given # interval until the cluster is found or the number of retries is reached.
#
# 


#region Get-TargetResource
#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (	
        [parameter(Mandatory)]
        [string] $Name,

        [parameter(Mandatory)]
        [string] $ClusterPrimaryNode,

        [UInt64] $RetryIntervalSec = 10,

        [UInt32] $RetryCount = 50,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential
    )

    @{
        Name = $Name
        ClusterPrimaryNode = $ClusterPrimaryNode
        RetryIntervalSec = $RetryIntervalSec
        RetryCount = $RetryCount
        DomainAdministratorCredential = $DomainAdministratorCredential
    }
}
#endregion Get-TargetResource

#region Set-TargetResource
#
# The Set-TargetResource cmdlet.
#
function Set-TargetResource
{
    param
    (	
        [parameter(Mandatory)]
        [string] $Name,

        [parameter(Mandatory)]
        [string] $ClusterPrimaryNode,

        [UInt64] $RetryIntervalSec = 10,

        [UInt32] $RetryCount = 50,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential
    )

    $clusterFound = $false
    Write-Verbose -Message "Checking for NLB Cluster $Name on primary cluster node $ClusterPrimaryNode ..."

    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        for ($count = 0; $count -lt $RetryCount; $count++)
        {
            try
            {
                $ComputerInfo = Get-WmiObject Win32_ComputerSystem
                if ($ComputerInfo -eq $null)
                {
                    Write-Verbose -Message "Can't find machine's info"
                    break;
                }
                $nlbcluster = Get-NLBCluster -HostName $ClusterPrimaryNode | Where-Object {$_.Name -eq "$Name"}
                if ($nlbcluster -ne $null)
                {
                    Write-Verbose -Message "Found NLB cluster $Name on primary node $ClusterPrimaryNode"
                    $clusterFound = $true
                    break;
                }            
            }
            catch
            {
                 Write-Verbose -Message "NLB Cluster $Name not found on node $ClusterPrimaryNode. Will retry again after $RetryIntervalSec sec"
            }
            
            Write-Verbose -Message "NLB cluster $Name not found on primary node $ClusterPrimaryNode. Will retry again after $RetryIntervalSec sec"
            Start-Sleep -Seconds $RetryIntervalSec
        }
        if (! $clusterFound)
        {
            throw "NLB cluster $Name not found on primary node $ClusterPrimaryNode after $count attempts with $RetryIntervalSec sec interval"
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured while checking for NLB cluster $Name on node $ClusterPrimaryNode. Error $($_.Message)"
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
}
#endregion Set-TargetResource

#region Test-TargetResource
#
# The Test-TargetResource cmdlet.
#
function Test-TargetResource
{
    [OutputType([Boolean])]
    param
    (	
        [parameter(Mandatory)]
        [string] $Name,

        [parameter(Mandatory)]
        [string] $ClusterPrimaryNode,

        [UInt64] $RetryIntervalSec = 10,

        [UInt32] $RetryCount = 50,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential
    )

    Write-Verbose -Message "Checking for NLB Cluster $Name on primary cluster node $ClusterPrimaryNode ..."
    try 
    {

        $ComputerInfo = Get-WmiObject Win32_ComputerSystem
        if ($ComputerInfo -eq $null)
        {
            Write-Verbose -Message "Can't find machine's info"
            $false
        }
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $nlbcluster = Get-NLBCluster -HostName $ClusterPrimaryNode -ErrorAction SilentlyContinue -ErrorVariable e | Where-Object {$_.Name -eq "$Name"}
        if ($nlbcluster -eq $null)
        {
            Write-Verbose -Message "NLB Cluster $Name not found on node $ClusterPrimaryNode"
            $false
        }
        else
        {
            Write-Verbose -Message "Found NLB cluster $Name on node $ClusterPrimaryNode"
            $true
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured while checking for NLB cluster $Name on node $ClusterPrimaryNode. Error $($_.Message)"
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
}
#endregion Test-TargetResource

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