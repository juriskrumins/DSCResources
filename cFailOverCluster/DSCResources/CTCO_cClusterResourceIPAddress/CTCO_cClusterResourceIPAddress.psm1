#Import DSC helper functions module
Import-Module -name DSCHelperFunctions

#region Get-TargetResource
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
        [parameter(Mandatory = $true)]
		[System.String[]]
		$Owners,

		[parameter(Mandatory = $true)]
		[System.String]
		$ClusterName,

		[parameter(Mandatory = $true)]
		[System.String]
		$SubnetMask,

		[parameter(Mandatory = $true)]
		[PSCredential]
		$DomainAdministratorCredential,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$GroupName,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[parameter(Mandatory = $true)]
		[System.String]
		$IPAddress
	)

    $retvalue = @{
            Owners = ""
            ClusterName = ""
            SubnetMask = ""
            DomainAdministratorCredential = ""
            Name = ""
            GroupName = ""
            Ensure = ""
            IPAddress = ""
    }
    try
    {
   
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $wfccluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue -ErrorVariable e
        if ($wfccluster -ne $null)
        {
            Write-Verbose "Specified WFC cluster found"
            $wfcclustergroup = $wfccluster | Get-ClusterGroup -Name $GroupName -ErrorAction SilentlyContinue -ErrorVariable g
            if ($wfcclustergroup -ne $null)
            {
                Write-Verbose "Specified WFC cluster group found"
                $wfcclusterresource = $wfcclustergroup | Get-ClusterResource -Name $Name -ErrorAction SilentlyContinue -ErrorVariable r
                if ($wfcclusterresource -ne $null)
                {
                    Write-Verbose "Specified WFC cluster resource found"
                    Write-Verbose "Collecting WFC cluster resource parameters"
                    $wfcclusterresourceparam=$wfcclusterresource | Get-ClusterParameter
                    $retvalue = @{
		                    Owners = ($wfcclusterresource | Get-ClusterOwnerNode).OwnerNodes.Name
		                    ClusterName = $wfcclusterresource.Cluster
		                    SubnetMask = $wfcclusterresourceparam.SubnetMask
		                    DomainAdministratorCredential = $DomainAdministratorCredential
		                    Name = $wfcclusterresource.Name
		                    GroupName = $wfcclusterresource.OwnerGroup
		                    Ensure = "Present"
		                    IPAddress = $wfcclusterresourceparam.Address
                    }
                }
                else
                {
                    Write-Verbose "Specified WFC cluster resource not found"
                    $retvalue = @{
		                    DomainAdministratorCredential = $DomainAdministratorCredential
                    }
                }

            }
            else
            {
                Write-Verbose "Specified WFC cluster group not found"
            }
        }
        else
        {
            Write-Verbose "Can't find WFC cluster $ClusterName."
        }
    }
    catch 
    {
        Write-Verbose -Message "General exception occured.$($Error[0])"
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
        [parameter(Mandatory = $true)]
		[System.String[]]
		$Owners,

		[parameter(Mandatory = $true)]
		[System.String]
		$ClusterName,

		[parameter(Mandatory = $true)]
		[System.String]
		$SubnetMask,

		[parameter(Mandatory = $true)]
		[PSCredential]
		$DomainAdministratorCredential,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$GroupName,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[parameter(Mandatory = $true)]
		[System.String]
		$IPAddress
	)

    try
    {
   
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $wfccluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue -ErrorVariable e
        if ($wfccluster -ne $null)
        {
            Write-Verbose "Specified WFC cluster found"
            $wfcclustergroup = $wfccluster | Get-ClusterGroup -Name $GroupName -ErrorAction SilentlyContinue -ErrorVariable g
            if ($wfcclustergroup -ne $null)
            {
                Write-Verbose "Specified WFC cluster group found"
                $wfcclusterresource = $wfcclustergroup | Get-ClusterResource -Name $Name -ErrorAction SilentlyContinue -ErrorVariable r
                if ($wfcclusterresource -ne $null)
                {
                    Write-Verbose "Specified WFC cluster resource found"
                    Write-Verbose "Collecting WFC cluster resource parameters"
                    $wfcclusterresourceparam=$wfcclusterresource | Get-ClusterParameter
                    if (($(Compare-Object (($wfcclusterresource | Get-ClusterOwnerNode).OwnerNodes.Name) $Owners) -eq $null) -and ($wfcclusterresourceparam[2].Value -eq $SubnetMask) -and ($wfcclusterresourceparam[1].Value -eq "$IPAddress"))
                    {
                        Write-Verbose "WFC cluster resource's $Name configuration correct."
                    }
                    else
                    {
                        Write-Verbose "WFC cluster resource's $Name configuration is not correct."
                        Write-Verbose "WFC cluster resource's $Name will be reconfigured ..."
                        Write-Verbose "Setting WFC cluster resource's $Name owners ..."
                        $wfcclusterresource | Set-ClusterOwnerNode -Owners $Owners
                        Write-Verbose "Setting WFC cluster resource's $Name parameters ..."
                        $wfcclusterresource | Set-ClusterParameter -Multiple @{"Address"="$IPAddress";"SubnetMask"="$SubnetMask"}
                        Write-Verbose "WFC cluster resource $Name reconfigured"
                        Write-Verbose "Restarting WFC cluster resource $Name ..."
                        $wfcclusterresource | Stop-ClusterResource -Wait 5 |Start-ClusterResource
                        Write-Verbose "WFC cluster resource $Name restarted"
                    }
                }
                else
                {
                    Write-Verbose "Specified WFC cluster resource not found"
                    Write-Verbose "WFC cluster resource $Name will be created in Group $GroupName."
                    $wfcclustergroup | Add-ClusterResource -Name $Name -ResourceType "IP Address"
                    Write-Verbose "WFC cluster resource $Name created in group $GroupName."
                    Write-Verbose "Setting WFC cluster resource's $Name parameters ..."
                    $wfcclusterresource = $wfcclustergroup | Get-ClusterResource -Name $Name -ErrorAction SilentlyContinue -ErrorVariable r
                    $wfcclusterresource | Set-ClusterParameter -Multiple @{"Address"="$IPAddress";"SubnetMask"="$SubnetMask"}
                    Write-Verbose "WFC cluster resource $Name configured"
                    Write-Verbose "Starting WFC cluster resource $Name ..."
                    $wfcclusterresource | Start-ClusterResource
                    Write-Verbose "WFC cluster resource $Name started."
                }

            }
            else
            {
                Write-Verbose "Specified WFC cluster group not found"
            }
        }
        else
        {
            Write-Verbose "Can't find WFC cluster $ClusterName."
        }
    }
    catch 
    {
        Write-Verbose -Message "General exception occured.$($Error[0])"
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
        [parameter(Mandatory = $true)]
		[System.String[]]
		$Owners,

		[parameter(Mandatory = $true)]
		[System.String]
		$ClusterName,

		[parameter(Mandatory = $true)]
		[System.String]
		$SubnetMask,

		[parameter(Mandatory = $true)]
		[PSCredential]
		$DomainAdministratorCredential,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$GroupName,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[parameter(Mandatory = $true)]
		[System.String]
		$IPAddress
	)

    $retvalue = $false
    try
    {
   
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $wfccluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue -ErrorVariable e
        if ($wfccluster -ne $null)
        {
            Write-Verbose "Specified WFC cluster found"
            $wfcclustergroup = $wfccluster | Get-ClusterGroup -Name $GroupName -ErrorAction SilentlyContinue -ErrorVariable g
            if ($wfcclustergroup -ne $null)
            {
                Write-Verbose "Specified WFC cluster group found"
                $wfcclusterresource = $wfcclustergroup | Get-ClusterResource -Name $Name -ErrorAction SilentlyContinue -ErrorVariable r
                if ($wfcclusterresource -ne $null)
                {
                    Write-Verbose "Specified WFC cluster resource found"
                    Write-Verbose "Collecting WFC cluster resource parameters"
                    $wfcclusterresourceparam=$wfcclusterresource | Get-ClusterParameter
                    if (((Compare-Object (($wfcclusterresource | Get-ClusterOwnerNode).OwnerNodes.Name) $Owners) -eq $null) -and ($wfcclusterresourceparam[2].Value -eq $SubnetMask) -and ($wfcclusterresourceparam[1].Value -eq $IPAddress))
                    {
                        Write-Verbose "WFC cluster resource's $Name configuration correct."
                        $retvalue = $true
                    }
                    else
                    {
                        Write-Verbose "WFC cluster resource's $Name configuration is not correct. Need to reconfigure resource."
                    }
                }
                else
                {
                    Write-Verbose "Specified WFC cluster resource not found"
                }

            }
            else
            {
                Write-Verbose "Specified WFC cluster group not found"
            }
        }
        else
        {
            Write-Verbose "Can't find WFC cluster $ClusterName."
        }
    }
    catch 
    {
        Write-Verbose -Message "General exception occured.$($Error[0])"
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