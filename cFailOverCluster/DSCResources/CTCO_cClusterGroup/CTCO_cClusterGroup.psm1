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
		[System.String]
		$ClusterName,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

        [parameter(Mandatory = $true)]
		[System.String[]]
		$Owners,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential
	)

    $retvalue = @{}
    try
    {
   
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $wfccluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue -ErrorVariable e
        if ($wfccluster -ne $null)
        {
            $wfcclustergroup = $wfccluster | Get-ClusterGroup -Name $Name -ErrorAction SilentlyContinue -ErrorVariable n
            if ($wfcclustergroup -ne $null)
            {
                Write-Verbose "Specified WFC cluster group found"
                $retvalue = @{
                        Name = $wfcclustergroup.Name
                        Owners = ($wfcclustergroup | Get-ClusterOwnerNode).OwnerNodes.Name
                        ClusterName = $wfcclustergroup.Cluster
                        DomainAdministratorCredential = $DomainAdministratorCredential
                        Ensure = "Present"
                }
            }
            else
            {
                Write-Verbose "Specified WFC cluster group not found"
                $retvalue = @{
                        Name = ""
                        Owners = ""
                        ClusterName = $wfcclustergroup.Cluster
                        DomainAdministratorCredential = $DomainAdministratorCredential
                        Ensure = "Absent"
                }
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
		[System.String]
		$ClusterName,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

        [parameter(Mandatory = $true)]
		[System.String[]]
		$Owners,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential
	)

    try
    {
   
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $wfccluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue -ErrorVariable e
        if ($wfccluster -ne $null)
        {
            $wfcclustergroup = $wfccluster | Get-ClusterGroup -Name $Name -ErrorAction SilentlyContinue -ErrorVariable n
            if ($wfcclustergroup -ne $null)
            {
                Write-Verbose "Specified WFC cluster group found"
                Write-Verbose "Reconfiguring WFC cluster group ..."
                $wfcclustergroup | Set-ClusterOwnerNode -Owners $Owners
                $wfcclustergroup | Move-ClusterGroup -Node $Owners[0]
                Write-Verbose "WFC cluster group configured succesfuly."
            }
            else
            {
                Write-Verbose "Specified WFC cluster group not found"
                Write-Verbose "Specified WFC cluster group will be created ..."
                $wfcclustergroup = $wfccluster  | Add-ClusterGroup -Name $Name 
                Write-Verbose "Specified WFC cluster group created succesfuly"
                Write-Verbose "Configuring WFC cluster group ..."
                $wfcclustergroup | Set-ClusterOwnerNode -Owners $Owners
                $wfcclustergroup | Move-ClusterGroup -Node $Owners[0]
                Write-Verbose "WFC cluster group configured succesfuly."
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
		[System.String]
		$ClusterName,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

        [parameter(Mandatory = $true)]
		[System.String[]]
		$Owners,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

        [parameter(Mandatory)]
        [PSCredential] $DomainAdministratorCredential
	)

    $retvalue = $false
    try
    {   
        ($oldToken, $context, $newToken) = ImpersonateAs -cred $DomainAdministratorCredential
        $wfccluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue -ErrorVariable e
        if ($wfccluster -ne $null)
        { 
            Write-Verbose "Specified WFC cluster $ClusterName found."
            Write-Verbose "Looking for WFC cluster group $Name."
            $wfcclustergroup = $wfccluster | Get-ClusterGroup -Name $Name -ErrorAction SilentlyContinue -ErrorVariable n
            if ($wfcclustergroup -ne $null)
            {
                Write-Verbose "Specified WFC cluster group found"
                Write-Verbose "Checking WFC cluster group configuration ..."
                $ClusterOwnerNodes=($wfcclustergroup | Get-ClusterOwnerNode).OwnerNodes.Name
                if($ClusterOwnerNodes.Length -eq $Owners.Length)
                {
                    $i=0
                    $reconfigure = $false
                    Foreach($Owner in $Owners) {
                        if($Owner -notlike $ClusterOwnerNodes[$i])
                        {
                            $reconfigure = $true
                            break
                        }
                    }
                    if(-not $reconfigure) 
                    {
                        $retvalue = $true
                        Write-Verbose "WFC cluster group's configuration looks good"
                    }
                    else
                    {
                        Write-Verbose "WFC cluster group's owner list should be reconfigured"
                    }
                } 
                else
                {
                    Write-Verbose "WFC cluster group's owner list should be reconfigured"
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

