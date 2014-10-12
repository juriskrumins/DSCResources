#
# cNLBCluster: DSC resource to configure a Windows NLB Cluster. If the cluster does not exist, it will create one in the 
# domain and assign the StaticIPAddress to the cluster. Then, it will add current node to the cluster.
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

        [parameter(Mandatory)]
        [string] $InterfaceName,
        
        [parameter(Mandatory)]
        [string] $ClusterPrimaryIP,

        [parameter(Mandatory=$true)]
        [ValidateSet("unicast", "multicast","igmpmulticast")]
        [string] $OperationMode,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential
    )

    try
    {
        $ComputerInfo = Get-WmiObject Win32_ComputerSystem
        if ($ComputerInfo -eq $null)
        {
            throw "Can't find machine's info."
        }
    
        try
        {
            ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
            $nlbcluster = Get-NLBCluster -HostName $ClusterPrimaryNode -InterfaceName $InterfaceName -ErrorAction SilentlyContinue -ErrorVariable e | Where-Object {$_.Name -eq "$($Name)"}
            if ($nlbcluster -eq $null)
            {
                throw "Can't find the NLB cluster $Name on node $ClusterPrimaryNode"
            }
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
    catch
    {
        Write-Verbose -Message "Error occured in Get-TargetResource function. Error $_.Message"
    }
    finally
    {
        $retvalue = @{
            Name = $nlbcluster.Name
            ClusterPrimaryNode = $ClusterPrimaryNode
            InterfaceName = $InterfaceName
            ClusterPrimaryIP = $nlbcluster.IPAddress
            OperationMode = $nlbcluster.OperationMode
        }
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

        [parameter(Mandatory)]
        [string] $InterfaceName,
        
        [parameter(Mandatory)]
        [string] $ClusterPrimaryIP,

        [parameter(Mandatory=$true)]
        [ValidateSet("unicast", "multicast","igmpmulticast")]
        [string] $OperationMode,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential
    )

    $bCreate = $true

    try
    {
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $ComputerInfo = Get-WmiObject Win32_ComputerSystem
        if ($ComputerInfo -eq $null)
        {
            throw "Can't find machine's info"
        }
        Write-Verbose -Message "Checking if NLB Cluster $Name is present on primary node $ClusterPrimaryNode..."
        $nlbcluster = Get-NLBCluster -HostName $ClusterPrimaryNode -InterfaceName $InterfaceName -ErrorAction SilentlyContinue -ErrorVariable e\| Where-Object {$_.Name -eq "$($Name)"}
        if ($nlbcluster)
        {
            $bCreate = $false     
        }
    }
    catch
    {
        $bCreate = $true
    }

    try
    {
        if ($bCreate)
        {
            Write-Verbose -Message "NLB Cluster $Name is NOT present on primary node $ClusterPrimaryNode"
            if($ComputerInfo.Name -eq $ClusterPrimaryNode) {
                try 
                {
                    New-NlbCluster -InterfaceName $InterfaceName -ClusterPrimaryIP $ClusterPrimaryIP -HostName localhost -OperationMode $OperationMode -ClusterName $Name -ErrorAction SilentlyContinue -ErrorVariable e
                    Write-Verbose -Message "NLB Cluster $Name on node $($ComputerInfo.Name) created."
                }
                catch 
                {
                    Write-Verbose -Message "Failed to create NLB Cluster $Name on node $($ComputerInfo.Name). Error $($_.Message)"
                }
            }
            else
            {
                Write-Verbose -Message "Node $($ComputerInfo.Name) is not NLB Cluster primary node."
                Write-Verbose -Message "Please use cWaitForNLBCluster Resource to make sure NLB cluster is configured on primary node $ClusterPrimaryNode."
            }
        }
        else
        {
            if($ComputerInfo.Name -eq $ClusterPrimaryNode) {
                    Write-Verbose -Message "Gathering NLB Cluster $Name configuration parameters ..."         
                    $nlbclusterip = $nlbcluster.IPAddress
                    Write-Verbose -Message "NLB cluster IP $nlbclusterip"
                    $nlbclustername = $nlbcluster.Name
                    Write-Verbose -Message "NLB cluster Name $nlbclustername"
                    $nlbclustermode = $nlbcluster.OperationMode
                    Write-Verbose -Message "NLB cluster OperationMode $nlbclustermode"
                    if (($nlbclusterip -ne $ClusterPrimaryIP) -or ($nlbclustername -ne $Name ) -or ($nlbclustermode -ne $OperationMode)) {
                        Write-Verbose -Message "Reconfigure NLB cluster $Name ..."
                        try 
                        {
                            $nlbcluster | Set-NlbCluster -Name $Name -OperationMode $OperationMode 
                            $nlbcluster | Get-NlbClusterVip | Set-NlbClusterVip -NewIP $ClusterPrimaryIP
                            Write-Verbose -Message "NLB cluster $Name have been reconfigured successfuly."
                        }
                        catch 
                        {
                            Write-Verbose -Message "NLB cluster $Name reconfiguration failed."
                        }
                    }
                    else
                    {
                        Write-Verbose -Message "NLB cluster $Name configured correctly."
                    }
            }
            else 
            {
                $nlbclusternodes=$nlbcluster | Get-NLBClusterNode
                if($nlbclusternodes.Name -contains $ComputerInfo.Name) 
                {
                    Write-Verbose -Message "Node $($ComputerInfo.Name) is already a part of NLB Cluster $Name."
                }
                else
                {
                    Write-Verbose -Message "Add node to NLB Cluster $Name using primary cluster node $ClusterPrimaryNode"
                    try
                    {
                        $nlbcluster | Add-NLBClusterNode -NewNodeName $ComputerInfo.Name -NewNodeInterface $InterfaceName -Force
                        Write-Verbose -Message "Succesfuly added node $($ComputerInfo.Name) to NLB Cluster $Name using primary cluster node $ClusterPrimaryNode"
                    }
                    catch 
                    {
                        Write-Verbose -Message "Failed to add node $($ComputerInfo.Name) to NLB Cluster $Name using primary cluster node $ClusterPrimaryNode"
                    }
                }
            }
        }
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
#
# The code will check the following in order: 
# 1. Is machine in domain?
# 2. Does the cluster exist in the domain?
# 3. Is the machine is in the cluster's nodelist?
# 4. Does the cluster node is UP?
#  
# Function will return FALSE if any above is not true. Which causes cluster to be configured.
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

        [parameter(Mandatory)]
        [string] $InterfaceName,
        
        [parameter(Mandatory)]
        [string] $ClusterPrimaryIP,

        [parameter(Mandatory=$true)]
        [ValidateSet("unicast", "multicast","igmpmulticast")]
        [string] $OperationMode,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential
    )

    $bRet = $false

    Write-Verbose -Message "Checking if NLB Cluster $Name is present ..."
    try
    {

        $ComputerInfo = Get-WmiObject Win32_ComputerSystem
        if ($ComputerInfo -eq $null)
        {
            Write-Verbose -Message "Can't find machine's info"
            $bRet = $false
        }
        else
        {
            try
            {
                ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential         
                $nlbcluster = Get-NLBCluster -HostName $ClusterPrimaryNode -InterfaceName $InterfaceName -ErrorAction SilentlyContinue -ErrorVariable e | Where-Object {$_.Name -ieq "$Name"}
                if ($nlbcluster)
                {
                    Write-Verbose -Message "NLB Cluster $Name is present on node $ClusterPrimaryNode"
                    Write-Verbose -Message "Gathering NLB Cluster $Name configuration parameters ..."
         
                    $nlbclusterip = $nlbcluster.IPAddress
                    Write-Verbose -Message "NLB cluster IP $nlbclusterip"
                    $nlbclustername = $nlbcluster.Name
                    Write-Verbose -Message "NLB cluster Name $nlbclustername"
                    $nlbclustermode = $nlbcluster.OperationMode
                    Write-Verbose -Message "NLB cluster OperationMode $nlbclustermode"

                    if (($nlbclusterip -eq $ClusterPrimaryIP) -and ($nlbclustername -eq $Name ) -and ($nlbclustermode -eq $OperationMode)) 
                    {
                        Write-Verbose -Message "NLB cluster $Name exists on node $ClusterPrimaryNode and configured correctly."
                        if ((Get-NLBClusterNode -HostName $ClusterPrimaryNode -InterfaceName $InterfaceName).Name -contains "$($ComputerInfo.Name)") {
                            Write-Verbose -Message "Node $($ComputerInfo.Name) is a part of NLB cluster $($Name)."
                            $bRet=$true
                        }
                        else 
                        {
                            Write-Verbose -Message "Node $($ComputerInfo.Name) is NOT a part of NLB cluster $($Name)."
                        }
                    } 
                    else
                    {
                             Write-Verbose -Message "NLB cluster $Name is up on node $ClusterPrimaryNode, but configured incorrectly."
                    }
                } 
                else
                {
                    Write-Verbose -Message "NLB Cluster $Name is NOT present on node $ClusterPrimaryNode"
                }

            }
            catch 
            {
                Write-Verbose -Message "Error occured while checking for NLB Cluster $Name on node $ClusterPrimaryNode. Error $($_.Message)"
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
    }
    catch
    {
        Write-Verbose -Message "NLB Cluster $Name is NOT present. Error $_.Message"
    }

    $bRet
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