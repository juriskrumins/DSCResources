#
# cNLBClustePortRule: DSC resource to configure a Windows NLB Cluster Port Rule.
#

#region Get-TargetResource
#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (	
        [parameter(Mandatory)]
        [string] $Name,

        [parameter(Mandatory)]
        [string] $ClusterName,

        [parameter(Mandatory)]
        [string] $ClusterPrimaryNode,

        [parameter()]
        [ValidateRange(0,65535)]
        [int] $StartPort=0,

        [parameter()]
        [ValidateRange(0,65535)]
        [int] $EndPort=65535,
        
        [parameter()]
        [ValidateSet("Network", "None","Single")]
        [string] $Affinity="Single",

        [parameter()]
        [ValidateSet("Disabled","Multiple","Single")]
        [string] $Mode="Multiple",

        [parameter()]
        [string] $IP="255.255.255.255",

        [parameter()]
        [ValidateSet("Both","TCP","UDP")]
        [string] $Protocol="Both",

        [parameter()]
        [ValidateRange(0,240)]
        [int] $Timeout=0,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential,

        [parameter()]
        [ValidateSet("Present", "Absent")]
        [string] $Ensure="Present"
    )

    $retvalue = @{}
    try
    {
   
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $nlbcluster = Get-NLBCluster -HostName $ClusterPrimaryNode -ErrorAction SilentlyContinue -ErrorVariable e | Where-Object {$_.Name -eq "$($ClusterName)"}
        if ($nlbcluster -ne $null)
        {
            $rules = $nlbcluster | Get-NlbClusterPortRule -ErrorAction SilentlyContinue -ErrorVariable n
            $nlbclusterportrule = $rules | Where-Object {($_.StartPort -eq $StartPort) -and ($_.EndPort -eq $EndPort) -and ($_.VirtualIPAddress -like "$IP")}
            if ($nlbclusterportrule -ne $null)
            {
                Write-Verbose "Specified NLB cluster port rule found"
                $retvalue = @{
                        Name = $nlbcluster.Name
                        ClusterPrimaryNode = $nlbclusterportrule.NodeName
                        StartPort = $nlbclusterportrule.Start
                        EndPort = $nlbclusterportrule.End
                        Affinity = $nlbclusterportrule.Affinity
                        Mode = $nlbclusterportrule.FilteringMode
                        IP = $nlbclusterportrule.VirtualIPAddress
                        Protocol = $nlbclusterportrule.Protocol
                        Timeout = $nlbclusterportrule.Timeout
                        DomainAdministratorCredential = $DomainAdministratorCredential
                        Ensure = "Present"
                }
            }
            else
            {
                Write-Verbose "Specified NLB cluster port rule not found"
                $retvalue = @{
                        Name = $nlbcluster.Name
                        ClusterPrimaryNode = $nlbclusterportrule.NodeName
                        DomainAdministratorCredential = $DomainAdministratorCredential
                }
            }
        }
        else
        {
            Write-Verbose "Can't find NLB cluster."
        }
    }
    catch 
    {
        Write-Verbose -Message "General exception.$($Error[0])"
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
    return $retvalue
}
#endregion Get-TargetResource

#region Set-TargetResource
#
# The Set-TargetResource cmdlet.
#
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [string] $Name,
        	
        [parameter(Mandatory)]
        [string] $ClusterName,

        [parameter(Mandatory)]
        [string] $ClusterPrimaryNode,

        [parameter()]
        [ValidateRange(0,65535)]
        [int] $StartPort=0,

        [parameter()]
        [ValidateRange(0,65535)]
        [int] $EndPort=65535,
        
        [parameter()]
        [ValidateSet("Network", "None","Single")]
        [string] $Affinity="Single",

        [parameter()]
        [ValidateSet("Disabled","Multiple","Single")]
        [string] $Mode="Multiple",

        [parameter()]
        [string] $IP="255.255.255.255",

        [parameter()]
        [ValidateSet("Both","TCP","UDP")]
        [string] $Protocol="Both",

        [parameter()]
        [ValidateRange(0,240)]
        [int] $Timeout=0,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential,

        [parameter()]
        [ValidateSet("Present", "Absent")]
        [string] $Ensure="Present"
    )

    try
    {
   
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $nlbcluster = Get-NLBCluster -HostName $ClusterPrimaryNode -ErrorAction SilentlyContinue -ErrorVariable e | Where-Object {$_.Name -eq "$($ClusterName)"}
        if ($nlbcluster -ne $null)
        {            
            $rules = $nlbcluster | Get-NlbClusterPortRule -ErrorAction SilentlyContinue -ErrorVariable n
            $nlbclusterportrule = $rules | Where-Object {($_.StartPort -eq $StartPort) -and ($_.EndPort -eq $EndPort) -and ($_.VirtualIPAddress -like "$IP")}
            if (($nlbclusterportrule -ne $null) -and ($Ensure -like "Present"))
            {
                if(($nlbclusterportrule.Affinity -like "$Affinity") -and ($nlbclusterportrule.FilteringMode -like "$Mode") -and ($nlbclusterportrule.Protocol -like "$Protocol") -and ($nlbclusterportrule.Timeout -eq $Timeout))
                {
                    Write-Verbose "Specified NLB cluster port rule found and configured correctly"
                }
                else 
                {
                    Write-Verbose "NLB cluster port rule will be reconfigured ..."
                    $nlbclusterportrule | Set-NlbClusterPortRule -NewAffinity $Affinity -NewMode $Mode -NewProtocol $Protocol -NewTimeout $Timeout
                }
            }
            elseif (($nlbclusterportrule -ne $null) -and ($Ensure -like "Absent"))
            {
                Write-Verbose "Specified NLB cluster port rule will be deleted"
                $nlbclusterportrule | Remove-NlbClusterPortRule -Force -ErrorAction Stop
            } 
            elseif (($nlbclusterportrule -eq $null) -and ($Ensure -like "Present"))
            {
                Write-Verbose "Specified NLB cluster port rule not found. Going to create NLB cluster rule ..."
                $nlbcluster | Add-NlbClusterPortRule -IP $IP -Protocol $Protocol -StartPort $StartPort -EndPort $EndPort -Mode $Mode -Affinity $Affinity -Timeout $Timeout -ErrorAction Stop
                Write-Verbose "Specified NLB cluster port rule created."
            }
            else 
            {
                Write-Verbose "Specified NLB cluster port rule shouldn't exist."
            }
        }
        else
        {
            Write-Verbose "Can't get NLB cluster $ClusterName."
        }
    }
    catch 
    {
        Write-Verbose -Message "General exception.$($Error[0])"
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
# Test-TargetResource
# Function will return FALSE if any above is not true. Which causes cluster to be configured.
# 
function Test-TargetResource  
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [parameter(Mandatory)]
        [string] $Name,
        	
        [parameter(Mandatory)]
        [string] $ClusterName,

        [parameter(Mandatory)]
        [string] $ClusterPrimaryNode,

        [parameter()]
        [ValidateRange(0,65535)]
        [int] $StartPort=0,

        [parameter()]
        [ValidateRange(0,65535)]
        [int] $EndPort=65535,
        
        [parameter()]
        [ValidateSet("Network", "None","Single")]
        [string] $Affinity="Single",

        [parameter()]
        [ValidateSet("Disabled","Multiple","Single")]
        [string] $Mode="Multiple",

        [parameter()]
        [string] $IP="255.255.255.255",

        [parameter()]
        [ValidateSet("Both","TCP","UDP")]
        [string] $Protocol="Both",

        [parameter()]
        [ValidateRange(0,240)]
        [int] $Timeout=0,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential,

        [parameter()]
        [ValidateSet("Present", "Absent")]
        [string] $Ensure="Present"
    )

    $retvalue = $false
    try
    {
   
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $nlbcluster = Get-NLBCluster -HostName $ClusterPrimaryNode -ErrorAction SilentlyContinue -ErrorVariable e | Where-Object {$_.Name -eq "$($ClusterName)"}
        if ($nlbcluster -ne $null)
        {
            $rules = $nlbcluster | Get-NlbClusterPortRule -ErrorAction SilentlyContinue -ErrorVariable n
            $nlbclusterportrule = $rules | Where-Object {($_.StartPort -eq $StartPort) -and ($_.EndPort -eq $EndPort) -and ($_.VirtualIPAddress -like "$IP")}
            if (($nlbclusterportrule -ne $null) -and ($Ensure -like "Present"))
            {
                Write-Verbose -Message "Specified NLB cluster port rule found"
                Write-Verbose -Message "$($nlbclusterportrule.Affinity) should be $Affinity"
                Write-Verbose -Message "$($nlbclusterportrule.FilteringMode) should be $Mode"
                Write-Verbose -Message "$($nlbclusterportrule.Protocol) should be $Protocol"
                Write-Verbose -Message "$($nlbclusterportrule.Timeout) should be $Timeout"
                if(($nlbclusterportrule.Affinity -like "$Affinity") -and ($nlbclusterportrule.FilteringMode -like "$Mode") -and ($nlbclusterportrule.Protocol -like "$Protocol") -and ($nlbclusterportrule.Timeout -eq $Timeout))
                {
                    Write-Verbose "NLB cluster port rule's configuration looks good"
                    $retvalue = $true
                }
                else 
                {
                    Write-Verbose "NLB cluster port rule need to be reconfigured"
                }
            }
            if (($nlbclusterportrule -eq $null) -and ($Ensure -like "Absent"))
            {
                Write-Verbose "Specified NLB cluster port rule shouldn't be found."
                $retvalue = $true
            }
            if (($nlbclusterportrule -ne $null) -and ($Ensure -like "Absent"))
            {
                Write-Verbose "Specified NLB cluster port rule should be deleted."
            }
            if (($nlbclusterportrule -eq $null) -and ($Ensure -like "Present"))
            {
                Write-Verbose "Specified NLB cluster port rule should exist."
            }
        }
        else
        {
            Write-Verbose "Can't get NLB Cluster $ClusterName."
        }
    }
    catch 
    {
        Write-Verbose -Message "General exception.$($Error[0])"
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
    return $retvalue
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