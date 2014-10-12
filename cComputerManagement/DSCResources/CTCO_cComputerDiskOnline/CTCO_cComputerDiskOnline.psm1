function Get-TargetResource
{
    [OutputType([Hashtable])]
	param
	(	
        [parameter(Mandatory)]
        [int] $DiskNumber
  	)

    $returnValue = @{}
    try
    {
        $ErrorActionPreference = "Stop"
        $disk = Get-Disk -Number $DiskNumber | Where-Object {-not $_.IsClustered}
        if ($disk -ne $null)
        {
            Write-Verbose -Message "Found disk $disk"
            $returnValue = @{
                DiskNumber = $disk.Number
                isOffline = $disk.isOffline
            }
        }
        else
        {
            Write-Verbose -Message "Disk not found"
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($Error[0].Exception.Message)"
    }
	$returnValue
}


function Set-TargetResource
{
	param
	(	
        [parameter(Mandatory)]
        [int] $DiskNumber
  	)

    try
    {
        $ErrorActionPreference = "Stop"
        $disk = Get-Disk -Number $DiskNumber | Where-Object {-not $_.IsClustered}
        if($disk -ne $null)
        {
            Write-Verbose -Message "Found disk $disk"
            if ($disk.isOffline)
            {
                Write-Verbose -Message "Try to take disk online ..."
                $disk | Set-Disk -IsOffline:$false
                Write-Verbose -Message "Disk is online"
            }
            else
            {
                Write-Verbose -Message "Disk is already Online"
            }
        }
        else
        {
            Write-Verbose -Message "Disk not found"
        }
    }
    catch 
    {
        Write-Verbose -Message "Error occured. Error $($Error[0].Exception.Message)"
    }

}


function Test-TargetResource
{
    [OutputType([Boolean])]
	param
	(	
        [parameter(Mandatory)]
        [int] $DiskNumber
  	)
    $retValue = $false
    $status = Get-TargetResource -DiskNumber $DiskNumber
    if (($status.keys -contains "DiskNumber") -and ($status.Keys -contains "isOffline"))
    {
        if ( -not $status.isOffline)
        {
                Write-Verbose -Message "Disk is already online."
                $retValue = $true
        }
    }
    else
    {
        Write-Verbose -Message "Can't find disk."
    }
    return $retValue
}


Export-ModuleMember -Function *-TargetResource