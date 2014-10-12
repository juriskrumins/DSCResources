function Get-TargetResource
{
    [OutputType([Hashtable])]
	param
	(	
        [parameter(Mandatory)]
        [int] $DiskNumber,
        [parameter(Mandatory)]
        [ValidateSet("MBR","GPT")]
        [string] $PartitionStyle
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
                PartitionStyle = $disk.PartitionStyle
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
        [int] $DiskNumber,
        [parameter(Mandatory)]
        [ValidateSet("MBR","GPT")]
        [string] $PartitionStyle
  	)

    try
    {
        $ErrorActionPreference = "Stop"
        $disk = Get-Disk -Number $DiskNumber | Where-Object {-not $_.IsClustered}
        if($disk -ne $null)
        {
            Write-Verbose -Message "Found disk $disk"
            if ($disk.PartitionStyle -eq "RAW")
            {
                Write-Verbose -Message "Try to initialize disk ..."
                $disk | Initialize-Disk -PartitionStyle $PartitionStyle
                Write-Verbose -Message "Disk have been initialized."
            }
            else
            {
                Write-Verbose -Message "Disk have been already initialized."
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
        [int] $DiskNumber,
        [parameter(Mandatory)]
        [ValidateSet("MBR","GPT")]
        [string] $PartitionStyle
  	)
    $retValue = $false
    $disk = Get-TargetResource -DiskNumber $DiskNumber -PartitionStyle $PartitionStyle
    if(($disk.keys -contains "DiskNumber") -and ($disk.Keys -contains "PartitionStyle"))
    {
        if ($disk.PartitionStyle -eq $PartitionStyle)
        {
            Write-Verbose -Message "Disk is alredy initialized using proper PartitionStyle: $($PartitionStyle)."
            $retValue = $true
        }
        elseif ($disk.PartitionStyle -eq "RAW")
        {
            Write-Verbose -Message "Disk should be initialized."
        }
        else
        {
            Write-Verbose -Message "Disk is alredy initialized using different PartitionStyle: $($disk.PartitionStyle)."
            Write-Verbose -Message "Disk will be skipped in order not to lose data."
            $retValue=$true
        }
    }
    else
    {
        Write-Verbose -Message "Can't find disk."
    }
    return $retValue
}


Export-ModuleMember -Function *-TargetResource