#Import DSC helper functions module
Import-Module -name DSCHelperFunctions

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
		$ValidateCluster=$false,

		[parameter(Mandatory = $false)]
		[System.String]
		$ClusterDiskName
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
                            ClusterDiskName = $wfcclusteravailabledisk.Name
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
        Write-Verbose -Message "General exception occured.$($_)"
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
		$ValidateCluster=$false,

		[parameter(Mandatory = $false)]
		[System.String]
		$ClusterDiskName

	)

    try
    {
        $ErrorActionPreference="Stop"
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $wfcclusteravailabledisk = Get-ClusterAvailableDisk -Disk (Get-Disk -Number $DiskNumber) -ErrorAction SilentlyContinue
        $physdisk = Get-Disk -Number $DiskNumber
        $physdisksign = ("0x{0:x}" -f $physdisk.CimInstanceProperties["Signature"].Value).ToUpper()
        $clustereddisks = (Get-ClusterResource -Cluster $ClusterName | Where-Object {$_.ResourceType -eq "Physical Disk"})
        $clustereddiskssigns = ($clustereddisks | Get-ClusterParameter DiskSignature).Value
        if(($clustereddiskssigns -notcontains $physdisksign) -and ($physdisk.IsClustered -eq $false) -and $wfcclusteravailabledisk -ne 0)
        {
            Write-Verbose "Found available disks in cluster. Disk with number $DiskNumber can be included in cluster $ClusterName"
            Write-Verbose "Try to add disk with number $DiskNumber to cluster's available disks list ..."
            $wfcclusterdisk = $wfcclusteravailabledisk | Add-ClusterDisk
            Write-Verbose "Disk with number $DiskNumber added to cluster $ClusterName as $($wfcclusterdisk.Name) to `"Available Storage`" cluster group."
            if($ClusterDiskName -ne $null -and $wfcclusterdisk.Name -ne "$ClusterDiskName")
            {
                Write-Verbose "Rename cluster disk $($wfcclusterdisk.Name) to $($ClusterDiskName)."
                $wfcclusterdisk.Name="$ClusterDiskName"
            }
            if($ValidateCluster)
            {
                Write-Verbose "Going to validate cluster $ClusterName."
                Test-Cluster -Cluster $ClusterName
            }
        }
        else
        {
            Write-Verbose "Disk with number $DiskNumber is already a part of cluster and thus is not in a list of available disks for cluster  $($ClusterName)."
            foreach ($clustereddisk in $clustereddisks)
            {
                $clustereddiskssign = $clustereddisk | Get-ClusterParameter DiskSignature
                if($clustereddiskssign.Value -eq "$physdisksign")
                {
                    $wfcclusterdisk=$clustereddisk
                    break
                }
            }
            if($ClusterDiskName -ne $null -and $wfcclusterdisk.Name -ne "$ClusterDiskName")
            {
                Write-Verbose "Cluster disk name is not correct."
                Write-Verbose "Rename cluster disk $($wfcclusterdisk.Name) to $($ClusterDiskName)."
                $wfcclusterdisk.Name="$ClusterDiskName"
            }
        }
    }
    catch 
    {
        Write-Verbose -Message "General exception occured.$($_)"
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
		$ValidateCluster=$false,

		[parameter(Mandatory = $false)]
		[System.String]
		$ClusterDiskName
	)

    $retvalue = $false
    try
    {
        $ErrorActionPreference="Stop"
        $physdisk = Get-Disk -Number $DiskNumber
        $physdisksign = ("0x{0:x}" -f $physdisk.Signature).ToUpper()
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $wfcclusteravailabledisk = Get-TargetResource -DiskNumber $DiskNumber -ClusterName $ClusterName -DomainAdministratorCredential $DomainAdministratorCredential -ClusterDiskName $ClusterDiskName -ValidateCluster $ValidateCluster
        $clustereddisks = (Get-ClusterResource -Cluster $ClusterName | Where-Object {$_.ResourceType -eq "Physical Disk"})
        $clustereddiskssigns = ($clustereddisks | Get-ClusterParameter DiskSignature).Value
        if(($clustereddiskssigns -contains $physdisksign) -and ($physdisk.IsClustered -eq $true) -and $wfcclusteravailabledisk.Count -eq 0)
        {
            Write-Verbose "Disk with number $DiskNumber is already a part of cluster $ClusterName."
            foreach ($clustereddisk in $clustereddisks)
            {
                $clustereddiskssign = $clustereddisk | Get-ClusterParameter DiskSignature
                if($clustereddiskssign.Value -eq "$physdisksign")
                {
                    $wfcclusterdisk=$clustereddisk
                    break
                }
            }
            if($ClusterDiskName -ne $null -and $wfcclusterdisk.Name -ne "$ClusterDiskName")
            {
                Write-Verbose "Cluster disk name is not correct and should be adjusted."
            }
            else
            {
                $retvalue=$true
            }
        }
        if(($clustereddiskssigns -notcontains $physdisksign) -and ($physdisk.IsClustered -eq $false) -and $wfcclusteravailabledisk.Count -ne 0)
        {
            Write-Verbose "Disk with number $DiskNumber is not clustered and is in the list of available disks for cluster $ClusterName."
        }
    }
    catch 
    {
        Write-Verbose -Message "General exception occured.$($_)"
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

Export-ModuleMember -Function *-TargetResource