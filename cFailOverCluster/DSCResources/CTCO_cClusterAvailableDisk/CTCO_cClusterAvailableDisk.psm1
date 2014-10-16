#region Get-TargetResource
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
        [parameter(Mandatory)]
        [int] $DiskNumber,

		[parameter(Mandatory = $true)]
		[System.String]
		$ClusterName,

		[parameter(Mandatory = $true)]
		[PSCredential]
		$DomainAdministratorCredential,

		[parameter()]
		[Boolean]
		$ValidateCluster=$false
	)

    $retvalue = @{}
    try
    {
        $ErrorActionPreference="Stop"
        $physdisk = Get-Disk -Number $DiskNumber
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $wfccluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue
        if ($wfccluster -ne $null)
        {
            Write-Verbose "Specified WFC cluster found"
            $wfcclusteravailabledisk = Get-ClusterAvailableDisk -Disk $physdisk -ErrorAction SilentlyContinue
            if ($wfcclusteravailabledisk -ne $null)
            {
                Write-Verbose "Found available disks in cluster. Disk with number $DiskNumber can be included in cluster $ClusterName"
                Write-Verbose "Collecting cluster available disk info ..."
                    $retvalue = @{
                            DiskNumber = $wfcclusteravailabledisk.Number
                            ClusterName = $wfcclusteravailabledisk.Cluster
                            DomainAdministratorCredential = $DomainAdministratorCredential
                            ValidateCluster = $ValidateCluster
                    }
                Write-Verbose "Cluster available disk info gathered."
            }
            else
            {
                Write-Verbose "Disk with number $DiskNumber is not in a list of available disks for cluster $ClusterName"
            }
        }
        else
        {
            Write-Verbose "Can't find WFC cluster $ClusterName."
        }
    }
    catch 
    {
        Write-Verbose -Message "General exception occured.$($Error[0].Exception.Message)"
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
function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
        [parameter(Mandatory)]
        [int] $DiskNumber,

		[parameter(Mandatory = $true)]
		[System.String]
		$ClusterName,

		[parameter(Mandatory = $true)]
		[PSCredential]
		$DomainAdministratorCredential,

		[parameter()]
		[Boolean]
		$ValidateCluster=$false
	)

    try
    {
        $ErrorActionPreference="Stop"
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $wfcclusteravailabledisk = Get-ClusterAvailableDisk -Disk (Get-Disk -Number $DiskNumber) -ErrorAction SilentlyContinue
        $physdisk = Get-Disk -Number $DiskNumber
        $physdisksign = ("0x{0:x}" -f $physdisk.CimInstanceProperties["Signature"].Value).ToUpper()
        $clustereddiskssign = (Get-ClusterResource -Cluster $ClusterName | Where-Object {$_.ResourceType -eq "Physical Disk"} | Get-ClusterParameter DiskSignature).Value
        if(($clustereddiskssign -notcontains $physdisksign) -and ($physdisk.IsClustered -eq $false) -and $wfcclusteravailabledisk -ne 0)
        {
            Write-Verbose "Found available disks in cluster. Disk with number $DiskNumber can be included in cluster $ClusterName"
            Write-Verbose "Try to add disk with number $DiskNumber to cluster's available disks list ..."
            $wfcclusterdisk = $wfcclusteravailabledisk | Add-ClusterDisk
            Write-Verbose "Disk with number $DiskNumber added to cluster $ClusterName as $($wfcclusterdisk.Name) to `"Available Storage`" cluster group."
            if($ValidateCluster)
            {
                Write-Verbose "Going to validate cluster $ClusterName."
                Test-Cluster -Cluster $ClusterName
            }
        }
        else
        {
            Write-Verbose "Disk with number $DiskNumber is already a part of cluster and thus is not in a list of available disks for cluster  $ClusterName."
        }
    }
    catch 
    {
        Write-Verbose -Message "General exception occured.$($Error[0].Exception.Message)"
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
function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
        [parameter(Mandatory)]
        [int] $DiskNumber,

		[parameter(Mandatory = $true)]
		[System.String]
		$ClusterName,

		[parameter(Mandatory = $true)]
		[PSCredential]
		$DomainAdministratorCredential,

		[parameter()]
		[Boolean]
		$ValidateCluster=$false
	)

    $retvalue = $false
    try
    {
        $ErrorActionPreference="Stop"
        $physdisk = Get-Disk -Number $DiskNumber
        $physdisksign = ("0x{0:x}" -f $physdisk.Signature).ToUpper()
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $wfcclusteravailabledisk = Get-TargetResource -DiskNumber $DiskNumber -ClusterName $ClusterName -DomainAdministratorCredential $DomainAdministratorCredential
        $clustereddiskssign = (Get-ClusterResource -Cluster $ClusterName | Where-Object {$_.ResourceType -eq "Physical Disk"} | Get-ClusterParameter DiskSignature).Value
        if(($clustereddiskssign -contains $physdisksign) -and ($physdisk.IsClustered -eq $true) -and $wfcclusteravailabledisk.Count -eq 0)
        {
            Write-Verbose "Disk with number $DiskNumber is already a part of cluster $ClusterName."
            $retvalue = $true
        }
        if(($clustereddiskssign -notcontains $physdisksign) -and ($physdisk.IsClustered -eq $false) -and $wfcclusteravailabledisk.Count -ne 0)
        {
            Write-Verbose "Disk with number $DiskNumber is not clustered and is in the list of available disks for cluster $ClusterName."
        }
    }
    catch 
    {
        Write-Verbose -Message "General exception occured.$($Error[0].Exception.Message)"
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

Export-ModuleMember -Function *-TargetResource